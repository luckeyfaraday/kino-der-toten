param([switch]$Extract, [string]$PatchedUnlinker = '')
$ErrorActionPreference = 'Stop'
$ascensionRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $ascensionRoot
function Invoke-AscensionStep {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
Invoke-AscensionStep 'py' @('-3.11','-c','import PIL')
if (-not (Test-Path -LiteralPath 'node_modules/three/package.json')) { Invoke-AscensionStep 'npm.cmd' @('ci') }
if ($Extract) {
    if (-not $PatchedUnlinker) { $PatchedUnlinker = (wsl.exe --exec sh -c 'printf %s $HOME') + '/oat/build/bin/Release_x64/Unlinker' }
    Invoke-AscensionStep '.tools/Unlinker.exe' @('--no-color','--include-assets','rawfile,xmodel,image,material','--model-format','OBJ','--image-format','DDS','--output-folder','export_ascension\?zone?',
        'zone/Common/zombie_cosmodrome.ff','zone/English/en_zombie_cosmodrome.ff','zone/Common/zombie_cosmodrome_patch.ff')
    Invoke-AscensionStep 'wsl.exe' @('--cd',$ascensionRoot,'--exec',$PatchedUnlinker,'--no-color','--include-assets','gfxworld,clipmap,mapents','--output-folder','export_ascension/world','zone/Common/zombie_cosmodrome.ff')
}
foreach ($ascensionInput in @('export_ascension/world/maps/zombie_cosmodrome.d3dbsp.gfxworld.json','export_ascension/world/maps/zombie_cosmodrome.d3dbsp.gfxworld.vd0','export_ascension/world/maps/zombie_cosmodrome.d3dbsp.gfxworld.idx','export_ascension/world/maps/zombie_cosmodrome.d3dbsp.ents')) {
    if (-not (Test-Path -LiteralPath $ascensionInput)) { throw "Missing Ascension dump: $ascensionInput. Run with -Extract; see ASCENSION_PORT.md." }
}
Invoke-AscensionStep 'py' @('-3.11','.tools/compose_scene_t5.py','--config','.tools/ascension-map.json')
Invoke-AscensionStep 'py' @('-3.11','.tools/build_ascension_data.py')
Invoke-AscensionStep 'node' @('.tools/bake-ascension.mjs')
Write-Host 'Ascension map build complete. Double-click Play Ascension.cmd.'
