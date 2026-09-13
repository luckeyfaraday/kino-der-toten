$ErrorActionPreference = 'Stop'
$kinoRoot = Split-Path -Parent $PSScriptRoot
$kinoPidFile = Join-Path $kinoRoot 'artifacts\server.pid'
if (-not (Test-Path -LiteralPath $kinoPidFile)) { Write-Host 'No launcher server is recorded.'; exit 0 }
$kinoServerPid = [int](Get-Content -LiteralPath $kinoPidFile -Raw)
$kinoProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$kinoServerPid"
$kinoServerScript = Join-Path $PSScriptRoot 'serve.mjs'
if ($kinoProcess -and $kinoProcess.Name -eq 'node.exe' -and $kinoProcess.CommandLine -match [regex]::Escape($kinoServerScript)) {
    Stop-Process -Id $kinoServerPid -ErrorAction Stop
    Remove-Item -LiteralPath $kinoPidFile
    Write-Host 'Kino server stopped.'
} elseif ($kinoProcess) {
    throw 'The recorded process is not this Kino server; it was left running.'
} else {
    Remove-Item -LiteralPath $kinoPidFile
    Write-Host 'Kino server is already stopped.'
}
