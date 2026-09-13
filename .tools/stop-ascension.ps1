$ErrorActionPreference = 'Stop'
$ascensionRoot = Split-Path -Parent $PSScriptRoot
$ascensionPidFile = Join-Path $ascensionRoot 'artifacts/ascension-server.pid'
if (Test-Path -LiteralPath $ascensionPidFile) {
    $ascensionServerId = [int](Get-Content -LiteralPath $ascensionPidFile)
    $ascensionProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $ascensionServerId"
    $ascensionScript = Join-Path $PSScriptRoot 'serve.mjs'
    if ($ascensionProcess -and $ascensionProcess.Name -eq 'node.exe' -and $ascensionProcess.CommandLine.Contains($ascensionScript)) {
        Stop-Process -Id $ascensionServerId
    }
    Remove-Item -LiteralPath $ascensionPidFile
    Write-Host 'Stopped the server started by the Ascension launcher.'
} else {
    Write-Host 'No server started by the Ascension launcher is recorded.'
}
