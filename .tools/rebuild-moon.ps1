param([switch]$Extract, [string]$PatchedUnlinker = '/home/alanq/oat/build/bin/Release_x64/Unlinker')
$ErrorActionPreference = 'Stop'
$moonRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $moonRoot
function Invoke-MoonStep {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
Invoke-MoonStep 'py' @('-3.11','-c','import PIL')
if (-not (Test-Path -LiteralPath 'node_modules/three/package.json')) { Invoke-MoonStep 'npm.cmd' @('ci') }
if ($Extract) {
    # Stock Windows OAT handles models/materials/scripts; the retained WSL build
    # has the additional T5 GfxWorld/clipMap dumpers used for Kino and Moon.
    Invoke-MoonStep '.tools/Unlinker.exe' @('--no-color','--include-assets','rawfile,xmodel,image,material','--model-format','OBJ','--image-format','DDS','--output-folder','export_moon\?zone?',
        'zone/Common/zombie_moon.ff','zone/English/en_zombie_moon.ff','zone/Common/zombie_moon_patch.ff')
    Invoke-MoonStep '.tools/Unlinker.exe' @('--no-color','--include-assets','xmodel,xanim,weapon','--model-format','GLB','--output-folder','export_moon/rigs/?zone?',
        'zone/Common/zombie_moon.ff','zone/Common/zombie_moon_patch.ff')
    Invoke-MoonStep 'wsl.exe' @('--cd',$moonRoot,'--exec',$PatchedUnlinker,'--no-color','--include-assets','gfxworld,clipmap,mapents','--output-folder','export_moon/world','zone/Common/zombie_moon.ff')
}
foreach ($moonInput in @('export_moon/world/maps/zombie_moon.d3dbsp.gfxworld.json','export_moon/world/maps/zombie_moon.d3dbsp.gfxworld.vd0','export_moon/world/maps/zombie_moon.d3dbsp.gfxworld.idx','export_moon/world/maps/zombie_moon.d3dbsp.ents')) {
    if (-not (Test-Path -LiteralPath $moonInput)) { throw "Missing Moon dump: $moonInput. Run with -Extract; see MOON_PORT.md." }
}
Invoke-MoonStep 'py' @('-3.11','.tools/build_moon_data.py')
Invoke-MoonStep 'py' @('-3.11','.tools/compose_scene_t5.py','--config','.tools/moon-map.json')
Invoke-MoonStep 'node' @('.tools/bake-moon.mjs')
Invoke-MoonStep 'py' @('-3.11','.tools/build_moon_combat.py')
Invoke-MoonStep 'py' @('-3.11','.tools/build_moon_audio.py')
Invoke-MoonStep 'py' @('-3.11','.tools/build_moon_presentation.py')
Invoke-MoonStep 'node' @('.tools/bake-moon-nav.mjs')
Invoke-MoonStep 'node' @('--test','test/moon.test.mjs','test/moon-combat.test.mjs','test/moon-progression.test.mjs','test/moon-enemies.test.mjs')
Write-Host 'Moon solo quest build complete. Double-click Play Moon.cmd to play.'
