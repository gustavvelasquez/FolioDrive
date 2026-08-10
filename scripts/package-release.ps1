# Empacota instalador + bundle para Release (Windows).
$ErrorActionPreference = "Stop"
$ProductDir = Split-Path $PSScriptRoot -Parent
$Version = (Get-Content (Join-Path $ProductDir "VERSIONS.json") | ConvertFrom-Json).product_version
$OutDir = Join-Path $ProductDir "dist"
$Pkg = "FolioDrive-$Version-installer"
$Tar = Join-Path $OutDir "$Pkg.tar.gz"

if (Test-Path (Join-Path $OutDir $Pkg)) { Remove-Item (Join-Path $OutDir $Pkg) -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $OutDir $Pkg) | Out-Null
Copy-Item (Join-Path $ProductDir "installer") (Join-Path $OutDir $Pkg\installer) -Recurse -Force
Copy-Item (Join-Path $ProductDir "bundle") (Join-Path $OutDir $Pkg\bundle) -Recurse -Force

if (Test-Path $Tar) { Remove-Item $Tar -Force }
Push-Location $OutDir
tar -czf $Tar $Pkg
Pop-Location
Write-Host "Release: $Tar"
