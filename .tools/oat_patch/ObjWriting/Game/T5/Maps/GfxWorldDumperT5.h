#pragma once

#include "Dumping/AbstractAssetDumper.h"
#include "Game/T5/T5.h"

namespace gfx_world
{
    class DumperT5 final : public AbstractAssetDumper<T5::AssetGfxWorld>
    {
    protected:
        void DumpAsset(AssetDumpingContext& context, const XAssetInfo<T5::AssetGfxWorld::Type>& asset) override;
    };
} // namespace gfx_world
