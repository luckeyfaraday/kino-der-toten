$ErrorActionPreference = 'Stop'
$moonRoot = Split-Path -Parent $PSScriptRoot
$moonPidFile = Join-Path $moonRoot 'artifacts/moon-server.pid'
if (Test-Path -LiteralPath $moonPidFile) {
    $moonServerId = [int](Get-Content -LiteralPath $moonPidFile)
    $moonProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $moonServerId"
    $moonScript = Join-Path $PSScriptRoot 'serve.mjs'
    if ($moonProcess -and $moonProcess.Name -eq 'node.exe' -and $moonProcess.CommandLine.Contains($moonScript)) { Stop-Process -Id $moonServerId }
    Remove-Item -LiteralPath $moonPidFile
}
Write-Host 'Moon server stopped.'
