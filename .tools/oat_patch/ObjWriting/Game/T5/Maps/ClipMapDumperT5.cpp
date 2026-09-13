#include "ClipMapDumperT5.h"

#include <cstdint>
#include <nlohmann/json.hpp>
#include <string>
#include <vector>

using namespace T5;
using namespace nlohmann;

namespace
{
    // The clipMap holds the authored collision hull, which is what the browser
    // runtime and the navmesh baker actually want -- the render world is only an
    // approximation of it.  Emitted as:
    //   <map>.clipmap.json      counts, materials, brushes, partitions, aabb trees
    //   <map>.clipmap.verts     raw vec3 collision vertices
    //   <map>.clipmap.tris      raw uint16 triangle indices (3 per triangle)
    //   <map>.clipmap.walkable  packed bitfield, one bit per triangle edge
    //
    // Array sizes follow src/ZoneCode/Game/T5/XAssets/clipMap_t.txt:
    //   triIndices        = 3 * triCount
    //   triEdgeIsWalkable = ((3 * triCount + 31) / 32) * 4 bytes

    json Vec3(const float (&v)[3])
    {
        return json::array({v[0], v[1], v[2]});
    }

    // Plane normals are the union type rather than a bare array.
    json Vec3(const vec3_t& v)
    {
        return json::array({v.x, v.y, v.z});
    }

    json BuildMaterials(const clipMap_t* clipMap)
    {
        auto materials = json::array();
        if (!clipMap->materials)
            return materials;

        for (auto i = 0u; i < clipMap->numMaterials; i++)
        {
            const auto& material = clipMap->materials[i];
            // material[64] is a fixed buffer and is not guaranteed to be
            // terminated, so bound the read explicitly.
            const auto* begin = material.material;
            const auto* end = begin;
            const auto* limit = begin + std::size(material.material);
            while (end < limit && *end)
                end++;

            materials.emplace_back(json{
                {"name",         std::string(begin, end)},
                {"surfaceFlags", material.surfaceFlags  },
                {"contentFlags", material.contentFlags  },
            });
        }

        return materials;
    }

    json BuildBrushes(const clipMap_t* clipMap)
    {
        auto brushes = json::array();
        if (!clipMap->brushes)
            return brushes;

        for (auto i = 0u; i < clipMap->numBrushes; i++)
        {
            const auto& brush = clipMap->brushes[i];

            auto sides = json::array();
            if (brush.sides)
            {
                for (auto s = 0u; s < brush.numsides; s++)
                {
                    const auto& side = brush.sides[s];
                    if (!side.plane)
                        continue;

                    sides.emplace_back(json{
                        {"normal", Vec3(side.plane->normal)},
                        {"dist",   side.plane->dist        },
                        {"cflags", side.cflags             },
                        {"sflags", side.sflags             },
                    });
                }
            }

            brushes.emplace_back(json{
                {"mins",     Vec3(brush.mins)},
                {"maxs",     Vec3(brush.maxs)},
                {"contents", brush.contents  },
                {"sides",    std::move(sides)},
            });
        }

        return brushes;
    }

    json BuildPartitions(const clipMap_t* clipMap)
    {
        auto partitions = json::array();
        if (!clipMap->partitions)
            return partitions;

        for (auto i = 0; i < clipMap->partitionCount; i++)
        {
            const auto& partition = clipMap->partitions[i];
            partitions.emplace_back(json{
                {"firstTri", partition.firstTri                   },
                {"triCount", static_cast<int>(partition.triCount) },
                {"nuinds",   partition.nuinds                     },
                {"fuind",    partition.fuind                      },
            });
        }

        return partitions;
    }

    json BuildAabbTrees(const clipMap_t* clipMap)
    {
        // Triangles carry no material of their own; the aabb tree leaves are
        // what attribute a partition of triangles to a collision material.
        auto trees = json::array();
        if (!clipMap->aabbTrees)
            return trees;

        for (auto i = 0; i < clipMap->aabbTreeCount; i++)
        {
            const auto& tree = clipMap->aabbTrees[i];
            const auto isLeaf = tree.childCount == 0;

            trees.emplace_back(json{
                {"origin",        Vec3(tree.origin)                   },
                {"halfSize",      Vec3(tree.halfSize)                 },
                {"materialIndex", static_cast<int>(tree.materialIndex)},
                {"childCount",    static_cast<int>(tree.childCount)   },
                {isLeaf ? "partitionIndex" : "firstChildIndex", tree.u.partitionIndex},
            });
        }

        return trees;
    }

    json BuildStaticModels(const clipMap_t* clipMap)
    {
        auto staticModels = json::array();
        if (!clipMap->staticModelList)
            return staticModels;

        for (auto i = 0u; i < clipMap->numStaticModels; i++)
        {
            const auto& model = clipMap->staticModelList[i];
            if (!model.xmodel || !model.xmodel->name)
                continue;

            staticModels.emplace_back(json{
                {"model",  model.xmodel->name             },
                {"origin", Vec3(model.origin)             },
                {"absmin", Vec3(model.absmin)             },
                {"absmax", Vec3(model.absmax)             },
                // Stored inverted and scaled by the engine; kept verbatim so the
                // consumer can decide how to invert it.
                {"invScaledAxis0", Vec3(model.invScaledAxis[0])},
                {"invScaledAxis1", Vec3(model.invScaledAxis[1])},
                {"invScaledAxis2", Vec3(model.invScaledAxis[2])},
            });
        }

        return staticModels;
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

    void DumpClipMap(AssetDumpingContext& context, const std::string& assetName, const clipMap_t* clipMap)
    {
        const auto triIndexCount = static_cast<size_t>(clipMap->triCount) * 3;
        const auto walkableBytes = clipMap->triCount > 0 ? ((triIndexCount + 31) / 32) * 4 : 0;

        if (!WriteBuffer(context, assetName + ".clipmap.verts", clipMap->verts, static_cast<size_t>(clipMap->vertCount) * sizeof(float) * 3))
            return;
        if (!WriteBuffer(context, assetName + ".clipmap.tris", clipMap->triIndices, triIndexCount * sizeof(uint16_t)))
            return;
        if (!WriteBuffer(context, assetName + ".clipmap.walkable", clipMap->triEdgeIsWalkable, walkableBytes))
            return;

        json root;
        root["name"] = clipMap->name ? clipMap->name : "";
        root["checksum"] = clipMap->checksum;
        root["vertCount"] = clipMap->vertCount;
        root["triCount"] = clipMap->triCount;
        root["walkableBytes"] = walkableBytes;
        root["materials"] = BuildMaterials(clipMap);
        root["brushes"] = BuildBrushes(clipMap);
        root["partitions"] = BuildPartitions(clipMap);
        root["aabbTrees"] = BuildAabbTrees(clipMap);
        root["staticModels"] = BuildStaticModels(clipMap);

        const auto jsonFile = context.OpenAssetFile(assetName + ".clipmap.json");
        if (!jsonFile)
            return;

        *jsonFile << root.dump(2);
    }
} // namespace

namespace clip_map
{
    void DumperT5::DumpAsset(AssetDumpingContext& context, const XAssetInfo<AssetClipMap::Type>& asset)
    {
        DumpClipMap(context, asset.m_name, asset.Asset());
    }

    void DumperPvsT5::DumpAsset(AssetDumpingContext& context, const XAssetInfo<AssetClipMapPvs::Type>& asset)
    {
        DumpClipMap(context, asset.m_name, asset.Asset());
    }
} // namespace clip_map
