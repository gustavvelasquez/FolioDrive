# Promove product/ para C:\Repositorios\FolioDrive (sem blobs pesados).
$ErrorActionPreference = "Stop"
$LabRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Product = Join-Path $LabRoot "product"
$ProdRoot = if ($env:PROD_ROOT) { $env:PROD_ROOT } else { Join-Path (Split-Path $LabRoot -Parent) "FolioDrive" }

if (-not (Test-Path $Product)) { throw "Ausente: $Product" }
New-Item -ItemType Directory -Force -Path $ProdRoot | Out-Null

$exclude = @('*.AppImage', '*.tar.gz', '*.run')
Get-ChildItem $Product -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Product.Length + 1)
    if ($rel -match '^bundle\\.*\.(AppImage|tar\.gz|run)$') { return }
    if ($rel -match '^bundle\\seadrive_extension\.py$') { return }
    if ($rel -match '^bundle\\data\\') { return }
    $dest = Join-Path $ProdRoot $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
    Copy-Item $_.FullName $dest -Force
}

foreach ($f in @('LICENSE', 'NOTICE', 'README.md')) {
    $src = Join-Path $Product $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $ProdRoot $f) -Force }
}

Write-Host "Promovido para: $ProdRoot"
