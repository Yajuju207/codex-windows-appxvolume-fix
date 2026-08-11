param(
    [switch]$Apply
)

$pkg = Get-AppxPackage OpenAI.Codex

if (-not $pkg) {
    Write-Error "OpenAI.Codex is not installed."
    exit 1
}

$systemVolume = Get-AppxVolume | Where-Object IsSystemVolume | Select-Object -First 1

Write-Host "Current package:" $pkg.PackageFullName
Write-Host "Target volume:" $systemVolume.PackageStorePath

if (-not $Apply) {
    Write-Host "Dry run only. Re-run with -Apply to move the package."
    exit 0
}

Write-Host "Moving Codex package..." -ForegroundColor Cyan
Move-AppxPackage -Package $pkg.PackageFullName -Volume $systemVolume -Verbose

Write-Host "Done. Restart Codex and check Computer Use."
