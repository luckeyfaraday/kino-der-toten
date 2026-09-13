param([switch]$Extract, [switch]$SkipAudio)
$ErrorActionPreference = 'Stop'
$kinoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $kinoRoot
function Invoke-KinoStep {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
Invoke-KinoStep 'py' @('-3.11','-c','import PIL')
if (-not (Test-Path -LiteralPath 'node_modules/three/package.json')) { Invoke-KinoStep 'npm.cmd' @('ci') }
if ($Extract) {
    Invoke-KinoStep '.tools/Unlinker.exe' @('--no-color','--include-assets','rawfile,weapon,xmodel,xanim,image,material,stringtable','--model-format','GLB','--image-format','DDS','--output-folder','export_game\?zone?',
        'zone/Common/common.ff','zone/Common/common_zombie.ff','zone/Common/zombie_theater.ff','zone/English/en_common_zombie.ff','zone/English/en_zombie_theater.ff','zone/Common/common_zombie_patch.ff','zone/Common/zombie_theater_patch.ff')
    Invoke-KinoStep '.tools/Unlinker.exe' @('--no-color','--include-assets','xmodel','--model-format','OBJ','--output-folder','export_localized_obj','zone/English/en_zombie_theater.ff')
}
foreach ($kinoInput in @('export/maps/zombie_theater.d3dbsp.gfxworld.json','export/maps/zombie_theater.d3dbsp.gfxworld.vd0','export/maps/zombie_theater.d3dbsp.gfxworld.idx','export_fmtprobe/maps/zombie_theater.d3dbsp.ents')) {
    if (-not (Test-Path -LiteralPath $kinoInput)) { throw "Missing world dump: $kinoInput. The original world extraction needs the patched OAT dumper; see RECONSTRUCTION.md." }
}
Invoke-KinoStep 'py' @('-3.11','.tools/build_game_assets.py')
Invoke-KinoStep 'py' @('-3.11','.tools/compose_scene_t5.py')
Invoke-KinoStep 'node' @('.tools/bake-world.mjs')
if (-not $SkipAudio) { Invoke-KinoStep 'py' @('-3.11','.tools/extract_audio.py') }
Invoke-KinoStep 'py' @('-3.11','.tools/write-provenance.py')
Invoke-KinoStep 'npm.cmd' @('test')
Invoke-KinoStep 'node' @('.tools/test-routes.mjs')
Write-Host 'Rebuild complete. Run Play Kino.cmd to play.'
