# Monta bundle/ no Windows (extensão, desktop, VERSIONS).
$ErrorActionPreference = "Stop"
$ProductDir = Split-Path $PSScriptRoot -Parent
$BundleDir = Join-Path $ProductDir "bundle"
$ExtDir = Join-Path $ProductDir "extension"

New-Item -ItemType Directory -Force -Path (Join-Path $BundleDir "data") | Out-Null
Copy-Item (Join-Path $ProductDir "VERSIONS.json") (Join-Path $BundleDir "VERSIONS.json") -Force
Copy-Item (Join-Path $ProductDir "assets\com.foliodrive.Files.desktop") (Join-Path $BundleDir "com.foliodrive.Files.desktop") -Force
Copy-Item (Join-Path $ExtDir "seadrive_extension.py") (Join-Path $BundleDir "seadrive_extension.py") -Force
if (Test-Path (Join-Path $ExtDir "data\icons")) {
    $dest = Join-Path $BundleDir "data\icons"
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item (Join-Path $ExtDir "data\icons") $dest -Recurse -Force
}
Write-Host "Bundle parcial/completo em $BundleDir"
