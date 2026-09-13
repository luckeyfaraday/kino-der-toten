import assert from 'node:assert/strict';

// Deduplicate bit-identical positions without changing a single triangle,
// triangle order, or the baked BVH. This is lossless, not mesh simplification.
export function compactCollision(original, source) {
  const layout = original.layout;
  assert.equal(layout.position.type, 'Float32Array');
  assert.equal(layout.index.type, 'Uint32Array');
  const bits = new Uint32Array(source.buffer, source.byteOffset + layout.position.byteOffset, layout.position.count);
  const indices = new Uint32Array(source.buffer, source.byteOffset + layout.index.byteOffset, layout.index.count);
  const unique = new Map(), remap = new Uint32Array(bits.length / 3), positions = new Uint32Array(bits.length);
  let count = 0;
  for (let i = 0; i < remap.length; i++) {
    const j = i * 3, key = `${bits[j]},${bits[j + 1]},${bits[j + 2]}`;
    let index = unique.get(key);
    if (index === undefined) {
      index = count++;
      unique.set(key, index);
      positions.set(bits.subarray(j, j + 3), index * 3);
    }
    remap[i] = index;
  }
  const compactIndices = new Uint32Array(indices.length);
  for (let i = 0; i < indices.length; i++) {
    const old = indices[i], next = remap[old];
    compactIndices[i] = next;
    for (let axis = 0; axis < 3; axis++) assert.equal(positions[next * 3 + axis], bits[old * 3 + axis], `Changed collision corner ${i}`);
  }
  const positionBytes = Buffer.from(positions.buffer, 0, count * 12);
  const indexBytes = Buffer.from(compactIndices.buffer);
  const chunks = [positionBytes, indexBytes];
  let offset = positionBytes.length + indexBytes.length;
  const roots = layout.roots.map(root => {
    const bytes = source.subarray(root.byteOffset, root.byteOffset + root.byteLength);
    chunks.push(bytes);
    const result = { byteOffset: offset, byteLength: bytes.length };
    offset += bytes.length;
    return result;
  });
  const metadata = { ...original, byteLength: offset, vertices: count, layout: {
    position: { byteOffset: 0, byteLength: positionBytes.length, type: 'Float32Array', count: count * 3 },
    index: { byteOffset: positionBytes.length, byteLength: indexBytes.length, type: 'Uint32Array', count: indices.length }, roots,
  } };
  return { metadata, binary: Buffer.concat(chunks), report: {
    sourceBytes: source.length, compactBytes: offset, sourceVertices: remap.length, uniqueVertices: count,
    verifiedTriangleCorners: indices.length, unchangedBVHBytes: roots.reduce((sum, root) => sum + root.byteLength, 0),
  } };
}
