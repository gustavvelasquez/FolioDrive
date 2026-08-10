#!/usr/bin/env bash
# Monta bundle/ a partir do lab (extensão, desktop, ícones, VERSIONS).
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LAB_ROOT="$(cd "${PRODUCT_DIR}/.." && pwd)"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
EXT_SRC="${LAB_ROOT}/forks/seadrive-ext"

mkdir -p "${BUNDLE_DIR}/data"

cp -f "${PRODUCT_DIR}/VERSIONS.json" "${BUNDLE_DIR}/VERSIONS.json"
cp -f "${PRODUCT_DIR}/assets/com.foliodrive.Files.desktop" \
  "${BUNDLE_DIR}/com.foliodrive.Files.desktop"

if [[ -f "${EXT_SRC}/seadrive_extension.py" ]]; then
  cp -f "${EXT_SRC}/seadrive_extension.py" "${BUNDLE_DIR}/seadrive_extension.py"
else
  echo "Extensão não encontrada: ${EXT_SRC}/seadrive_extension.py"
  exit 1
fi

if [[ -d "${EXT_SRC}/data/icons" ]]; then
  rm -rf "${BUNDLE_DIR}/data/icons"
  cp -a "${EXT_SRC}/data/icons" "${BUNDLE_DIR}/data/"
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
        print(f"AUSENTE (build maintainer): {p.name}")
PY

if [[ "${missing}" -eq 1 ]]; then
  echo ""
  echo "Bundle parcial OK (extensão + desktop)."
  echo "Faltam blobs — maintainer:"
  echo "  ./scripts/fetch-seadrive.sh"
  echo "  ./scripts/build-foliodrive-files.sh"
  echo "  ./scripts/update-versions.sh"
else
  echo "Bundle completo em ${BUNDLE_DIR}"
fi
