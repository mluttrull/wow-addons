# Symlinks every addon in this repo into the WoW Forever AddOns folder.
# Run from an elevated PowerShell (symlinks need admin unless Developer Mode is on):
#   powershell -ExecutionPolicy Bypass -File tools\install.ps1
# Pass -WowDir if your game isn't in the default location.
param(
    [string]$WowDir = "C:\Program Files (x86)\World of Warcraft"
)

$repo = Split-Path -Parent $PSScriptRoot
$addons = Join-Path $WowDir "_forever_\Interface\AddOns"

if (-not (Test-Path (Join-Path $WowDir "_forever_"))) {
    Write-Host "No _forever_ folder under $WowDir." -ForegroundColor Red
    Write-Host "Find it in Battle.net: pick WoW Forever above Play, gear icon, Show in Explorer, then rerun with -WowDir <path>."
    exit 1
}
New-Item -ItemType Directory -Force -Path $addons | Out-Null

$skip = @("HelloAzeroth")
Get-ChildItem -Directory $repo | Where-Object { Test-Path (Join-Path $_.FullName "$($_.Name).toc") } | ForEach-Object {
    $name = $_.Name
    if ($skip -contains $name) { return }
    $target = Join-Path $addons $name
    if (Test-Path $target) {
        $item = Get-Item $target
        if ($item.LinkType -eq "SymbolicLink") { Remove-Item $target -Force }
        else { Write-Host "skip $name: a real folder already exists at $target" -ForegroundColor Yellow; return }
    }
    New-Item -ItemType SymbolicLink -Path $target -Target $_.FullName | Out-Null
    Write-Host "linked $name -> $target" -ForegroundColor Green
}
Write-Host "`nDone. Restart the game client fully (not /reload) so it discovers the new folders."
