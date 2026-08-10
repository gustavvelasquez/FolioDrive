# Verifica bundle + checksums (sem instalar).
$ErrorActionPreference = "Stop"
$ProductDir = Split-Path $PSScriptRoot -Parent
python (Join-Path $PSScriptRoot "verify_bundle.py") $ProductDir
