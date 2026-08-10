# Tarball wrapper foliodrive-files (Windows / Git Bash tar).
$ErrorActionPreference = "Stop"
$ProductDir = Split-Path $PSScriptRoot -Parent
$BundleDir = Join-Path $ProductDir "bundle"
$Stage = Join-Path $env:TEMP "foliodrive-wrapper-stage"
$Tarball = Join-Path $BundleDir "foliodrive-files-46.0-foliodrive.1.tar.gz"

Remove-Item -Recurse -Force $Stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$Stage\opt\foliodrive\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$Stage\opt\foliodrive\share\nautilus-python\extensions" | Out-Null

@'
#!/usr/bin/env bash
export XDG_DATA_DIRS="/opt/foliodrive/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
if [[ -x /opt/foliodrive/bin/nautilus-real ]]; then
  exec /opt/foliodrive/bin/nautilus-real "$@"
fi
if [[ -x /usr/bin/nautilus ]]; then
  exec /usr/bin/nautilus "$@"
fi
echo "foliodrive-files: nautilus nao encontrado."
exit 1
'@ | Set-Content -NoNewline -Path "$Stage\opt\foliodrive\bin\foliodrive-files" -Encoding utf8

if (Test-Path $Tarball) { Remove-Item $Tarball -Force }
Push-Location $Stage
tar -czf $Tarball opt/foliodrive
Pop-Location
Write-Host "OK: $Tarball"
