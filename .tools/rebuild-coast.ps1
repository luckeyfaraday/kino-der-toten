param([switch]$Extract, [string]$PatchedUnlinker = '/home/alanq/oat/build/bin/Release_x64/Unlinker')
$ErrorActionPreference = 'Stop'
$coastRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $coastRoot
function Invoke-CoastStep {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
Invoke-CoastStep 'py' @('-3.11','-c','import PIL')
if (-not (Test-Path -LiteralPath 'node_modules/three/package.json')) { Invoke-CoastStep 'npm.cmd' @('ci') }
if ($Extract) {
    Invoke-CoastStep '.tools/Unlinker.exe' @('--no-color','--include-assets','rawfile,xmodel,image,material','--model-format','OBJ','--image-format','DDS','--output-folder','export_coast\?zone?',
        'zone/Common/zombie_coast.ff','zone/English/en_zombie_coast.ff','zone/Common/zombie_coast_patch.ff')
    Invoke-CoastStep 'wsl.exe' @('--cd',$coastRoot,'--exec',$PatchedUnlinker,'--no-color','--include-assets','gfxworld,clipmap,mapents','--output-folder','export_coast/world','zone/Common/zombie_coast.ff')
}
foreach ($coastInput in @('gfxworld.json','gfxworld.vd0','gfxworld.idx','ents')) {
    if (-not (Test-Path -LiteralPath "export_coast/world/maps/zombie_coast.d3dbsp.$coastInput")) { throw "Missing coast world dump: $coastInput. Run with -Extract." }
}
Invoke-CoastStep 'py' @('-3.11','.tools/build_coast_data.py')
Invoke-CoastStep 'py' @('-3.11','.tools/compose_scene_t5.py','--config','.tools/coast-map.json')
Invoke-CoastStep 'node' @('.tools/bake-coast.mjs')
Write-Host 'Call of the Dead map built. Double-click Play Call of the Dead.cmd.'
