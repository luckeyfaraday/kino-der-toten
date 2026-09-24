param([switch]$Extract, [string]$PatchedUnlinker = '')
$ErrorActionPreference = 'Stop'
$shangriRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $shangriRoot
function Invoke-ShangriStep {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
Invoke-ShangriStep 'py' @('-3.11','-c','import PIL')
if (-not (Test-Path -LiteralPath 'node_modules/three/package.json')) { Invoke-ShangriStep 'npm.cmd' @('ci') }
if ($Extract) {
    if (-not $PatchedUnlinker) { $PatchedUnlinker = (wsl.exe --exec sh -c 'printf %s $HOME') + '/oat/build/bin/Release_x64/Unlinker' }
    Invoke-ShangriStep '.tools/Unlinker.exe' @('--no-color','--include-assets','rawfile,xmodel,image,material','--model-format','OBJ','--image-format','DDS','--output-folder','export_shangri_la\?zone?',
        'zone/Common/zombie_temple.ff','zone/English/en_zombie_temple.ff','zone/Common/zombie_temple_patch.ff')
    Invoke-ShangriStep 'wsl.exe' @('--cd',$shangriRoot,'--exec',$PatchedUnlinker,'--no-color','--include-assets','gfxworld,clipmap,mapents','--output-folder','export_shangri_la/world','zone/Common/zombie_temple.ff')
}
foreach ($shangriInput in @('export_shangri_la/world/maps/zombie_temple.d3dbsp.gfxworld.json','export_shangri_la/world/maps/zombie_temple.d3dbsp.gfxworld.vd0','export_shangri_la/world/maps/zombie_temple.d3dbsp.gfxworld.idx','export_shangri_la/world/maps/zombie_temple.d3dbsp.ents')) {
    if (-not (Test-Path -LiteralPath $shangriInput)) { throw "Missing Shangri-La dump: $shangriInput. Run with -Extract; see SHANGRI_LA_PORT.md." }
}
Invoke-ShangriStep 'py' @('-3.11','.tools/compose_scene_t5.py','--config','.tools/shangri-la-map.json')
Invoke-ShangriStep 'py' @('-3.11','.tools/build_shangri_la_data.py')
Invoke-ShangriStep 'node' @('.tools/bake-shangri-la.mjs')
Write-Host 'Shangri-La map build complete. Double-click Play Shangri-La.cmd.'
