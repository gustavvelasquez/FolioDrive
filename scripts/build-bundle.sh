#!/usr/bin/env bash
# Monta bundle/ (extensão, desktop, VERSIONS). Repo FolioDrive é self-contained.
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
EXT_SRC="${PRODUCT_DIR}/extension"

# Fallback lab layout (StorageOneDriveLike/product)
if [[ ! -f "${EXT_SRC}/seadrive_extension.py" ]]; then
  LAB_EXT="$(cd "${PRODUCT_DIR}/../.." 2>/dev/null && pwd)/forks/seadrive-ext"
  if [[ -f "${LAB_EXT}/seadrive_extension.py" ]]; then
    EXT_SRC="${LAB_EXT}"
  fi
fi

mkdir -p "${BUNDLE_DIR}/data"

cp -f "${PRODUCT_DIR}/VERSIONS.json" "${BUNDLE_DIR}/VERSIONS.json"
cp -f "${PRODUCT_DIR}/assets/com.foliodrive.Files.desktop" \
  "${BUNDLE_DIR}/com.foliodrive.Files.desktop"

if [[ ! -f "${EXT_SRC}/seadrive_extension.py" ]]; then
  echo "Extensão não encontrada em extension/ ou forks/seadrive-ext"
  exit 1
fi

cp -f "${EXT_SRC}/seadrive_extension.py" "${BUNDLE_DIR}/seadrive_extension.py"

if [[ -d "${EXT_SRC}/data/icons" ]]; then
  rm -rf "${BUNDLE_DIR}/data/icons"
  cp -a "${EXT_SRC}/data/icons" "${BUNDLE_DIR}/data/"
elif [[ -d "${EXT_SRC}/icons" ]]; then
  rm -rf "${BUNDLE_DIR}/data/icons"
  cp -a "${EXT_SRC}/icons" "${BUNDLE_DIR}/data/icons"
fi

missing=0
python3 - "${BUNDLE_DIR}/VERSIONS.json" <<'PY' || missing=1
import json, sys
from pathlib import Path
data = json.load(open(sys.argv[1]))
bundle = Path(sys.argv[1]).parent
for comp in data["components"].values():
    p = bundle / comp["file"]
    if not p.is_file():
        print(f"AUSENTE: {p.name}")
PY

if [[ "${missing}" -eq 1 ]]; then
  echo ""
  echo "Bundle parcial (extensão + desktop + ícones)."
  echo "Próximo: ./scripts/fetch-seadrive.sh && ./scripts/build-foliodrive-files.sh"
else
  echo "Bundle completo em ${BUNDLE_DIR}"
fi
