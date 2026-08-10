#!/usr/bin/env bash
# Maintainer: baixa SeaDrive AppImage pinado UMA vez (não roda no install do usuário).
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
VERSIONS="${PRODUCT_DIR}/VERSIONS.json"

need_cmd() { command -v "$1" >/dev/null || { echo "Falta: $1"; exit 1; }; }
need_cmd wget
need_cmd python3

version="$(python3 -c "import json; print(json.load(open('${VERSIONS}'))['components']['seadrive_appimage']['version'])")"
file="$(python3 -c "import json; print(json.load(open('${VERSIONS}'))['components']['seadrive_appimage']['file'])")"
url="$(python3 -c "import json; print(json.load(open('${VERSIONS}'))['components']['seadrive_appimage']['upstream_url'])")"

mkdir -p "${BUNDLE_DIR}"
dest="${BUNDLE_DIR}/${file}"

if [[ -f "${dest}" ]]; then
  echo "Já existe: ${dest}"
  exit 0
fi

echo "Baixando SeaDrive ${version} (maintainer only)…"
wget -4 -O "${dest}.partial" "${url}"
chmod +x "${dest}.partial"
mv "${dest}.partial" "${dest}"
echo "OK: ${dest}"
echo "Rode: ./scripts/update-versions.sh"
