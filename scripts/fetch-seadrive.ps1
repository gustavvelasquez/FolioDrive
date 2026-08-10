# Maintainer: baixa SeaDrive AppImage pinado (Windows).
$ErrorActionPreference = "Stop"
$ProductDir = Split-Path $PSScriptRoot -Parent
$BundleDir = Join-Path $ProductDir "bundle"
$Versions = Get-Content (Join-Path $ProductDir "VERSIONS.json") | ConvertFrom-Json
$file = $Versions.components.seadrive_appimage.file
$url = $Versions.components.seadrive_appimage.upstream_url
$dest = Join-Path $BundleDir $file
New-Item -ItemType Directory -Force -Path $BundleDir | Out-Null
if (Test-Path $dest) { Write-Host "Ja existe: $dest"; exit 0 }
Write-Host "Baixando $url ..."
Invoke-WebRequest -Uri $url -OutFile "$dest.partial" -UseBasicParsing
Move-Item "$dest.partial" $dest -Force
Write-Host "OK: $dest"
