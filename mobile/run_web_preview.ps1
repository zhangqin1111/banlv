$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $scriptDir 'build\web'
$python = 'D:\aicode\zhiyu\backend\.venv\Scripts\python.exe'
$port = 18081

if (!(Test-Path $buildDir)) {
  throw "Web build not found. Run .\\flutterw.ps1 build web first."
}

if (!(Test-Path $python)) {
  throw "Python runtime not found at $python"
}

$alreadyListening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if (-not $alreadyListening) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $python
  $psi.Arguments = "-m http.server $port --directory `"$buildDir`""
  $psi.WorkingDirectory = $scriptDir
  $psi.UseShellExecute = $true
  $psi.WindowStyle = 'Hidden'
  [System.Diagnostics.Process]::Start($psi) | Out-Null
  Start-Sleep -Seconds 2
}

Start-Process 'chrome.exe' "http://127.0.0.1:$port"
