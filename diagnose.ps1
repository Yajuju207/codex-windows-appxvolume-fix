$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Codex package ===" -ForegroundColor Cyan
$pkg = Get-AppxPackage OpenAI.Codex
$pkg | Format-List Name,Version,InstallLocation,PackageFullName

Write-Host "`n=== Appx volumes ===" -ForegroundColor Cyan
Get-AppxVolume | Format-Table Name,PackageStorePath,IsSystemVolume

Write-Host "`n=== Codex volume registration ===" -ForegroundColor Cyan
Get-AppxVolume | ForEach-Object {
    $vol = $_
    $found = Get-AppxPackage -Volume $vol | Where-Object Name -eq "OpenAI.Codex"
    if ($found) {
        Write-Host "Found on:" $vol.PackageStorePath -ForegroundColor Yellow
        $found | Select-Object Name,Version,InstallLocation
    }
}

if ($pkg) {
    $node = Join-Path $pkg.InstallLocation "app\resources\cua_node\bin\node_repl.exe"
    Write-Host "`n=== node_repl protection ===" -ForegroundColor Cyan
    if (Test-Path $node) {
        cipher /c $node
    }
}

$runtime = "$env:LOCALAPPDATA\OpenAI\Codex\runtimes\cua_node"
Write-Host "`n=== Runtime staging ===" -ForegroundColor Cyan
"Runtime exists: $(Test-Path $runtime)"
"Runtime files : $(@(Get-ChildItem $runtime -Recurse -File).Count)"

Write-Host "`n=== Helper files ===" -ForegroundColor Cyan
Get-ChildItem $runtime -Recurse -File -ErrorAction SilentlyContinue |
Where-Object Name -in @("node_repl.exe","codex-computer-use.exe","helper_transport.js") |
Select-Object Name,FullName
