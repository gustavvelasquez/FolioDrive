#!/usr/bin/env bash
# Fallback: empacota nautilus do Ubuntu 24.04 (versão apt pinada) em /opt/foliodrive.
# Usado quando build meson falha; binário renomeado para foliodrive-files.
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
PREFIX="/opt/foliodrive"
TARBALL_NAME="foliodrive-files-46.0-foliodrive.1.tar.gz"
STAGE="${STAGE:-/tmp/foliodrive-apt-stage}"
NAUTILUS_VER="${NAUTILUS_VER:-}"

log() { printf '\n==> %s\n' "$*"; }

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Não rode como root."
  exit 1
fi

log "Instalar nautilus (apt) para capturar versão pinada"
sudo apt-get update -y
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y nautilus python3-nautilus

if [[ -z "${NAUTILUS_VER}" ]]; then
  NAUTILUS_VER="$(dpkg-query -W -f='${Version}' nautilus 2>/dev/null || true)"
fi
if [[ -z "${NAUTILUS_VER}" ]]; then
  echo "Não foi possível detectar versão do nautilus"
  exit 1
fi

log "Versão apt nautilus: ${NAUTILUS_VER}"

rm -rf "${STAGE}"
mkdir -p "${STAGE}${PREFIX}/bin" "${STAGE}${PREFIX}/share/applications"

# Binário e libs listadas pelo pacote
NAU_BIN="$(command -v nautilus)"
cp -a "${NAU_BIN}" "${STAGE}${PREFIX}/bin/foliodrive-files"

# Copiar share data do nautilus (ícones, schemas, etc.)
if [[ -d /usr/share/nautilus ]]; then
  mkdir -p "${STAGE}${PREFIX}/share"
  cp -a /usr/share/nautilus "${STAGE}${PREFIX}/share/"
fi

# Registrar versão pinada para VERSIONS.json
mkdir -p "${PRODUCT_DIR}/build-meta"
echo "${NAUTILUS_VER}" > "${PRODUCT_DIR}/build-meta/nautilus-apt-version.txt"

mkdir -p "${BUNDLE_DIR}"
tar -czf "${BUNDLE_DIR}/${TARBALL_NAME}" -C "${STAGE}" opt/foliodrive

log "Tarball (apt): ${BUNDLE_DIR}/${TARBALL_NAME}"
echo "nautilus_apt_version=${NAUTILUS_VER}"
