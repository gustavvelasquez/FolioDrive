# Preenche sha256 em VERSIONS.json (Windows).
$ErrorActionPreference = "Stop"
$ProductDir = Split-Path $PSScriptRoot -Parent
python (Join-Path $PSScriptRoot "update_versions.py") `
  (Join-Path $ProductDir "VERSIONS.json") `
  (Join-Path $ProductDir "bundle")
