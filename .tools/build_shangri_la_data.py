"""Build the map-only viewer's source data and asset audit from local T5 dumps."""
import hashlib
import io
import json
import math
from pathlib import Path
import re
import struct
from urllib.parse import unquote
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CONFIG = json.loads((ROOT / '.tools/shangri-la-map.json').read_text())
OUT = ROOT / CONFIG['output']
WORLD = ROOT / (CONFIG['world'] + '.json')
ENTS = ROOT / CONFIG['entities']


def position(text):
    x, y, z = map(float, text.split())
    return [x, z, -y]


world = json.loads(WORLD.read_text())
entities = [dict(re.findall(r'"([^"\n]+)"\s*"([^"\n]*)"', block))
            for block in re.findall(r'\{([^{}]*)\}', ENTS.read_text())]
for index, entity in enumerate(entities):
    entity['id'] = index
    if 'origin' in entity:
        entity['position'] = position(entity['origin'])
    entity['yaw'] = math.radians(float(entity.get('angles', '0 0 0').split()[1]))

spawn = next(e for e in entities if e.get('targetname') == 'initial_spawn_points')
doc = json.loads((OUT / 'shangri-la.gltf').read_text())
composition = json.loads((OUT / 'composition.json').read_text())
if composition['missingModels']:
    raise RuntimeError(f"Missing map models: {composition['missingModels']}")
missing_textures = [im['uri'] for im in doc['images'] if not (OUT / unquote(im['uri'])).is_file()]
if missing_textures:
    raise RuntimeError(f'Missing exported textures: {missing_textures}')

# Pillow reads only the first DDS cubemap face. Split all six DXT1 faces,
# preserving their pixels and native order (+X, -X, +Y, -Y, +Z, -Z).
sky = ROOT / 'export_shangri_la/zombie_temple/images/skybox_zombie_temple_ft.dds'
raw = sky.read_bytes()
height, width = struct.unpack_from('<2I', raw, 12)
mip_count = max(1, struct.unpack_from('<I', raw, 28)[0])
assert raw[84:88] == b'DXT1' and struct.unpack_from('<I', raw, 112)[0] & 0xfe00 == 0xfe00
face_size = sum(max(1, (max(1, width >> mip) + 3) // 4) *
                max(1, (max(1, height >> mip) + 3) // 4) * 8 for mip in range(mip_count))
assert len(raw) == 128 + face_size * 6, 'Unexpected native sky cubemap size'
header = bytearray(raw[:128])
struct.pack_into('<I', header, 112, 0)
sky_faces = []
for i, label in enumerate(['px', 'nx', 'py', 'ny', 'pz', 'nz']):
    name = f'textures/sky-{label}.png'
    face = bytes(header) + raw[128 + i * face_size:128 + (i + 1) * face_size]
    Image.open(io.BytesIO(face)).convert('RGB').save(OUT / name)
    sky_faces.append(name)
sky_material = json.loads((ROOT / 'export_shangri_la/zombie_temple/materials/mc/mtl_skybox_zombie_temple_2.json').read_text())

untextured = [m['extras']['sourceMaterialNames'] for m in doc['materials']
              if 'baseColorTexture' not in m['pbrMetallicRoughness']]
material_rules = {}
for directory in CONFIG['assetDirs']:
    material_root = ROOT / directory / 'materials'
    for file in material_root.rglob('*.json'):
        definition = json.loads(file.read_text())
        name = file.relative_to(material_root).as_posix()[:-5]
        technique = definition.get('techniqueSet', '')
        # The tree-canopy technique also shades visible leaves. Only its null
        # meshes and shadow/gobo cards are invisible in the normal map view.
        if name == 'mc/t5_foliage_null' or ('foliage' in name and ('gobo' in name or name.endswith('_shadow'))):
            material_rules[name] = {'hidden': True, 'technique': technique}
        if name.endswith('water_dynamic'):
            constants = {c['name']: c['literal'] for c in definition.get('constants', [])}
            material_rules[name] = {'water': True, 'color': constants.get('waterColorN', [.1, .2, .2, .85])}
data = {
    'map': 'zombie_temple', 'title': 'Shangri-La', 'stage': 'map-only',
    'spawn': {'position': spawn['position'], 'yaw': spawn['yaw'], 'entity': spawn['id']},
    'entities': entities, 'worldspawn': entities[0],
    'materialRules': material_rules,
    'hiddenEntities': [e['id'] for e in entities if e.get('targetname') == 'sq_meteorite'],
    'sky': {'faces': sky_faces, 'constants': sky_material['constants']},
    'source': {'world': CONFIG['world'] + '.json', 'entities': CONFIG['entities']},
}
(OUT / 'map-data.json').write_text(json.dumps(data, separators=(',', ':')))
sources = []
for relative in ['zone/Common/zombie_temple.ff', 'zone/English/en_zombie_temple.ff', 'zone/Common/zombie_temple_patch.ff']:
    source = ROOT / relative
    with source.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    sources.append({'path': relative, 'bytes': source.stat().st_size, 'sha256': digest})
(OUT / 'provenance.json').write_text(json.dumps({
    'map': data['map'], 'stage': data['stage'], 'sources': sources,
    'entities': len(entities), 'staticPlacements': len(world['staticModels']),
    'scriptModels': composition['scriptModels'], 'missingModels': composition['missingModels'],
    'textures': len(doc['images']), 'untexturedMaterials': untextured,
    'pipeline': '.tools/compose_scene_t5.py (same composer as Kino)',
}, indent=2))
print(f"Shangri-La: {len(entities)} entities, {len(world['staticModels'])} static placements, "
      f"{composition['scriptModels']} scripted props, {len(doc['images'])} textures")
print(f'Untextured material groups: {len(untextured)} (see provenance.json)')
