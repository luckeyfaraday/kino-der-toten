#!/bin/bash
# Applies the T5 world-export patch to an OpenAssetTools checkout.
#
# OAT loads T5 GfxWorld/clipMap correctly but ships no dumper for either, so the
# Kino map shell cannot be exported by a stock build. This drops in the missing
# dumpers and registers them in ObjWriterT5.
#
# Usage: apply.sh <path-to-OpenAssetTools-checkout>
set -euo pipefail

OAT="${1:?usage: apply.sh <path-to-OpenAssetTools>}"
HERE="$(cd "$(dirname "$0")" && pwd)"

[[ -f "$OAT/premake5.lua" ]] || { echo "not an OpenAssetTools checkout: $OAT" >&2; exit 1; }

cp -rv "$HERE/ObjWriting/." "$OAT/src/ObjWriting/"

# --- upstream portability fixes (unrelated to the dumpers) -------------------
# OAT at 51770e7 does not build with GCC 13; two pre-existing issues.

# std::sqrtf is not mandated by libstdc++; std::sqrt has a float overload.
sed -i 's/std::sqrtf(/std::sqrt(/g' "$OAT/src/ObjLoading/Game/T5/XModel/XModelHighMipVolumeT5.cpp"

# Uses std::format without including <format>.
MENU_WRITER="$OAT/src/ObjWriting/Game/IW3/Menu/MenuWriterIW3.cpp"
if ! grep -q '#include <format>' "$MENU_WRITER"; then
    sed -i 's|#include <cassert>|#include <cassert>\n#include <format>|' "$MENU_WRITER"
fi
# -----------------------------------------------------------------------------

WRITER="$OAT/src/ObjWriting/Game/T5/ObjWriterT5.cpp"

# Both edits are idempotent so the script can be re-run after a git pull.
if ! grep -q 'Maps/GfxWorldDumperT5.h' "$WRITER"; then
    sed -i 's|#include "Game/T5/Maps/MapEntsDumperT5.h"|#include "Game/T5/Maps/ClipMapDumperT5.h"\n#include "Game/T5/Maps/GfxWorldDumperT5.h"\n#include "Game/T5/Maps/MapEntsDumperT5.h"|' "$WRITER"
    echo "registered dumper includes"
fi

if ! grep -q 'gfx_world::DumperT5' "$WRITER"; then
    sed -i 's|    // REGISTER_DUMPER(AssetDumperGfxWorld, m_gfx_world)|    RegisterAssetDumper(std::make_unique<gfx_world::DumperT5>());|' "$WRITER"
    echo "registered GfxWorldDumperT5"
fi

if ! grep -q 'clip_map::DumperT5' "$WRITER"; then
    sed -i 's|    // REGISTER_DUMPER(AssetDumperClipMap, m_clip_map)|    RegisterAssetDumper(std::make_unique<clip_map::DumperT5>());|' "$WRITER"
    echo "registered ClipMapDumperT5"
fi

# Guarded separately from DumperT5: a tree patched by an earlier revision of this
# script already has DumperT5 and would otherwise never gain the PVS dumper,
# which is the one shipped zones actually use.
if ! grep -q 'clip_map::DumperPvsT5' "$WRITER"; then
    sed -i 's|    RegisterAssetDumper(std::make_unique<clip_map::DumperT5>());|&\n    RegisterAssetDumper(std::make_unique<clip_map::DumperPvsT5>());|' "$WRITER"
    echo "registered ClipMapDumperPvsT5"
fi

grep -n 'GfxWorld\|ClipMap\|clip_map\|gfx_world' "$WRITER"

echo
echo "Patch applied. Now run, from $OAT:"
echo "  PREMAKE_NO_PROMPT=1 ./generate.sh   # picks up the new source files"
echo "  make -C build -j\$(nproc) config=release_x64 all"
