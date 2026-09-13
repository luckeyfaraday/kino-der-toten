$ErrorActionPreference = 'Stop'
$shangriRoot = Split-Path -Parent $PSScriptRoot
$shangriPidFile = Join-Path $shangriRoot 'artifacts/shangri-la-server.pid'
if (Test-Path -LiteralPath $shangriPidFile) {
    $shangriServerId = [int](Get-Content -LiteralPath $shangriPidFile)
    $shangriProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $shangriServerId"
    $shangriScript = Join-Path $PSScriptRoot 'serve.mjs'
    if ($shangriProcess -and $shangriProcess.Name -eq 'node.exe' -and $shangriProcess.CommandLine.Contains($shangriScript)) {
        Stop-Process -Id $shangriServerId
    }
    Remove-Item -LiteralPath $shangriPidFile
    Write-Host 'Stopped the server started by the Shangri-La launcher.'
} else {
    Write-Host 'No server started by the Shangri-La launcher is recorded.'
}
