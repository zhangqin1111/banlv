$ErrorActionPreference = "Stop"

$projectSkills = Join-Path $PSScriptRoot "*"
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$dest = Join-Path $codexHome "skills"

New-Item -ItemType Directory -Force -Path $dest | Out-Null

Get-ChildItem -Directory -Path $PSScriptRoot | ForEach-Object {
    if ($_.Name -in @(".git", ".svn")) { return }
    $target = Join-Path $dest $_.Name
    if (Test-Path $target) {
        Remove-Item -Recurse -Force -LiteralPath $target
    }
    Copy-Item -Recurse -Force -LiteralPath $_.FullName -Destination $target
    Write-Host "Installed skill: $($_.Name)"
}

Write-Host ""
Write-Host "Done. Restart Codex to pick up project skills."
