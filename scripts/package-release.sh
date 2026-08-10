#!/usr/bin/env bash
# Empacota instalador + bundle para GitHub Release.
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(python3 -c "import json; print(json.load(open('${PRODUCT_DIR}/VERSIONS.json'))['product_version'])")"
OUT_DIR="${PRODUCT_DIR}/dist"
PKG="FolioDrive-${VERSION}-installer"
TAR="${OUT_DIR}/${PKG}.tar.gz"

mkdir -p "${OUT_DIR}"
rm -rf "${OUT_DIR}/${PKG}"
mkdir -p "${OUT_DIR}/${PKG}"

cp -a "${PRODUCT_DIR}/installer" "${OUT_DIR}/${PKG}/"
cp -a "${PRODUCT_DIR}/bundle" "${OUT_DIR}/${PKG}/"

chmod +x "${OUT_DIR}/${PKG}/installer/install-foliodrive.sh"
chmod +x "${OUT_DIR}/${PKG}/installer/steps/"*.sh 2>/dev/null || true

tar -czf "${TAR}" -C "${OUT_DIR}" "${PKG}"
echo "Release artifact: ${TAR}"
echo "Usuário: tar -xzf ${PKG}.tar.gz && cd ${PKG} && ./installer/install-foliodrive.sh"
