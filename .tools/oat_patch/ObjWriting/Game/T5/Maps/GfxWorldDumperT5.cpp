#include "GfxWorldDumperT5.h"

#include <cstddef>
#include <nlohmann/json.hpp>
#include <string>
#include <unordered_map>
#include <vector>

using namespace T5;
using namespace nlohmann;

namespace
{
    // The world shell is emitted as three files that mirror the T6 export
    // contract consumed by .tools/compose_scene.py:
    //   <map>.gfxworld.json  metadata: surfaces, materials, static models
    //   <map>.gfxworld.vd0   raw GfxWorldVertex buffer
    //   <map>.gfxworld.idx   raw uint16 index buffer
    // Vertex layout is described in the JSON rather than assumed, because the
    // T5 vertex is 44 bytes with float32 texcoords while T6's is 36 with
    // float16 texcoords.

    const char* MaterialColorMap(const Material* material)
    {
        if (!material || !material->textureTable)
            return nullptr;

        for (auto i = 0u; i < material->textureCount; i++)
        {
            const auto& texture = material->textureTable[i];
            if (texture.semantic == TS_COLOR_MAP && texture.u.image && texture.u.image->name)
                return texture.u.image->name;
        }

        return nullptr;
    }

    json Vec3(const float (&v)[3])
    {
        return json::array({v[0], v[1], v[2]});
    }

    // Materials are shared by many surfaces; intern them so the JSON carries a
    // small table and the surfaces carry indices into it.
    class MaterialTable
    {
    public:
        size_t Intern(const Material* material)
        {
            const auto existing = m_indices.find(material);
            if (existing != m_indices.end())
                return existing->second;

            const auto index = m_entries.size();
            m_indices.emplace(material, index);

            json entry;
            entry["name"] = material && material->info.name ? material->info.name : "";
            const auto* colorMap = MaterialColorMap(material);
            if (colorMap)
                entry["colorMap"] = colorMap;
            else
                entry["colorMap"] = nullptr;
            m_entries.emplace_back(std::move(entry));

            return index;
        }

        [[nodiscard]] const std::vector<json>& Entries() const
        {
            return m_entries;
        }

    private:
        std::unordered_map<const Material*, size_t> m_indices;
        std::vector<json> m_entries;
    };

    json BuildVertexLayout()
    {
        return json{
            {"stride",    sizeof(GfxWorldVertex)                                                                     },
            {"position",  json{{"offset", offsetof(GfxWorldVertex, xyz)}, {"format", "float32x3"}}                    },
            {"color",     json{{"offset", offsetof(GfxWorldVertex, color)}, {"format", "rgba8"}}                      },
            {"texCoord",  json{{"offset", offsetof(GfxWorldVertex, texCoord)}, {"format", "float32x2"}}               },
            {"lmapCoord", json{{"offset", offsetof(GfxWorldVertex, lmapCoord)}, {"format", "float32x2"}}              },
            {"normal",    json{{"offset", offsetof(GfxWorldVertex, normal)}, {"format", "packedUnitVec"}}             },
            {"tangent",   json{{"offset", offsetof(GfxWorldVertex, tangent)}, {"format", "packedUnitVec"}}            },
        };
    }

    json BuildSurfaces(const GfxWorld* world, MaterialTable& materials)
    {
        auto surfaces = json::array();
        if (!world->dpvs.surfaces)
            return surfaces;

        const auto stride = static_cast<size_t>(sizeof(GfxWorldVertex));
        for (auto i = 0; i < world->surfaceCount; i++)
        {
            const auto& surface = world->dpvs.surfaces[i];
            const auto& tris = surface.tris;

            surfaces.emplace_back(json{
                {"m",  materials.Intern(surface.material)                          },
                {"fv", tris.firstVertex                                            },
                {"vc", tris.vertexCount                                            },
                {"tc", tris.triCount                                               },
                {"bi", tris.baseIndex                                              },
                // Byte offset of the surface's first vertex, so the composer can
                // index the raw buffer without knowing the stride twice over.
                {"o0", static_cast<size_t>(tris.firstVertex) * stride              },
                {"flags", static_cast<int>(surface.flags)                          },
                {"lightmapIndex", static_cast<int>(surface.lightmapIndex)          },
                {"mins", Vec3(tris.mins)                                           },
                {"maxs", Vec3(tris.maxs)                                           },
            });
        }

        return surfaces;
    }

    json BuildStaticModels(const GfxWorld* world)
    {
        auto staticModels = json::array();
        if (!world->dpvs.smodelDrawInsts)
            return staticModels;

        for (auto i = 0u; i < world->dpvs.smodelCount; i++)
        {
            const auto& inst = world->dpvs.smodelDrawInsts[i];
            if (!inst.model || !inst.model->name)
                continue;

            const auto& placement = inst.placement;
            staticModels.emplace_back(json{
                {"model",    inst.model->name          },
                {"origin",   Vec3(placement.origin)    },
                {"axis0",    Vec3(placement.axis[0])   },
                {"axis1",    Vec3(placement.axis[1])   },
                {"axis2",    Vec3(placement.axis[2])   },
                {"scale",    placement.scale           },
                {"flags",    inst.flags                },
                {"cullDist", inst.cullDist             },
            });
        }

        return staticModels;
    }

    json BuildBrushModels(const GfxWorld* world)
    {
        auto brushModels = json::array();
        if (!world->models)
            return brushModels;

        for (auto i = 0; i < world->modelCount; i++)
        {
            const auto& model = world->models[i];
            brushModels.emplace_back(json{
                {"mins",            Vec3(model.bounds[0])},
                {"maxs",            Vec3(model.bounds[1])},
                {"surfaceCount",    model.surfaceCount   },
                {"startSurfIndex",  model.startSurfIndex },
            });
        }

        return brushModels;
    }

    bool WriteBuffer(AssetDumpingContext& context, const std::string& fileName, const void* data, const size_t size)
    {
        const auto file = context.OpenAssetFile(fileName);
        if (!file)
            return false;

        if (data && size > 0)
            file->write(static_cast<const char*>(data), static_cast<std::streamsize>(size));

        return true;
    }
} // namespace

namespace gfx_world
{
    void DumperT5::DumpAsset(AssetDumpingContext& context, const XAssetInfo<AssetGfxWorld::Type>& asset)
    {
        const auto* world = asset.Asset();

        const auto vertexCount = static_cast<size_t>(world->draw.vertexCount);
        const auto indexCount = static_cast<size_t>(world->draw.indexCount);

        if (!WriteBuffer(context, asset.m_name + ".gfxworld.vd0", world->draw.vd.vertices, vertexCount * sizeof(GfxWorldVertex)))
            return;
        if (!WriteBuffer(context, asset.m_name + ".gfxworld.idx", world->draw.indices, indexCount * sizeof(uint16_t)))
            return;

        MaterialTable materials;
        // Surfaces must be built before the material table is serialised, since
        // interning happens while walking them.
        auto surfaces = BuildSurfaces(world, materials);

        json root;
        root["name"] = world->name ? world->name : "";
        root["baseName"] = world->baseName ? world->baseName : "";
        root["checksum"] = world->checksum;
        root["mins"] = Vec3(world->mins);
        root["maxs"] = Vec3(world->maxs);
        root["vertexCount"] = vertexCount;
        root["indexCount"] = indexCount;
        root["surfaceCount"] = world->surfaceCount;
        root["vertexLayout"] = BuildVertexLayout();
        root["surfaces"] = std::move(surfaces);
        root["staticModels"] = BuildStaticModels(world);
        root["brushModels"] = BuildBrushModels(world);
        root["materials"] = materials.Entries();

        const auto jsonFile = context.OpenAssetFile(asset.m_name + ".gfxworld.json");
        if (!jsonFile)
            return;

        *jsonFile << root.dump(2);
    }
} // namespace gfx_world
