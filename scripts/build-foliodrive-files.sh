#!/usr/bin/env bash
# Build Nautilus fork → foliodrive-files tarball (Ubuntu 26.04 GNOME, maintainer).
# Produz binário ELF em /opt/foliodrive (NÃO o wrapper bash → /usr/bin/nautilus).
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
BUILD_ROOT="${BUILD_ROOT:-/tmp/foliodrive-nautilus-build}"
NAUTILUS_TAG="${NAUTILUS_TAG:-50.2.2}"
PREFIX="/opt/foliodrive"
TARBALL_NAME="foliodrive-files-50.2.2-foliodrive.1.tar.gz"
# Fallback apt só copia o binário do SO (mesmo app-id) — NÃO usar no produto.
USE_APT_FALLBACK="${USE_APT_FALLBACK:-0}"
# VM com pouca RAM: -j1
NINJA_JOBS="${NINJA_JOBS:-1}"

log() { printf '\n==> %s\n' "$*"; }

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Não rode como root."
  exit 1
fi

if [[ "${USE_APT_FALLBACK}" == "1" ]]; then
  exec "${PRODUCT_DIR}/scripts/build-foliodrive-files-apt.sh"
fi

_build_meson() {
  log "Dependências de build (meson) — Nautilus ${NAUTILUS_TAG}"
  sudo apt-get update -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential meson ninja-build pkg-config git \
    libglib2.0-dev libgtk-4-dev libadwaita-1-dev \
    libportal-dev libportal-gtk4-dev \
    libgexiv2-dev libcloudproviders-dev libcue-dev \
    libxml2-dev libsqlite3-dev \
    python3-nautilus libnautilus-extension-dev \
    gettext desktop-file-utils shared-mime-info \
    libtinysparql-dev 2>/dev/null \
    || sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential meson ninja-build pkg-config git \
      libglib2.0-dev libgtk-4-dev libadwaita-1-dev \
      libportal-dev libportal-gtk4-dev \
      libgexiv2-dev libcloudproviders-dev libcue-dev \
      libxml2-dev libsqlite3-dev \
      python3-nautilus libnautilus-extension-dev \
      gettext desktop-file-utils shared-mime-info

  # tracker/sparql: nome do pacote varia por release
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libtinysparql-3.0-dev 2>/dev/null \
    || sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      libtracker-sparql-3.0-dev 2>/dev/null \
    || true

  rm -rf "${BUILD_ROOT}"
  mkdir -p "${BUILD_ROOT}"
  cd "${BUILD_ROOT}"

  log "Clone Nautilus ${NAUTILUS_TAG}"
  if [[ -d nautilus ]]; then
    rm -rf nautilus
  fi
  # Preferir tarball oficial (mais leve que git completo)
  TARBALL_URL="https://download.gnome.org/sources/nautilus/50/nautilus-${NAUTILUS_TAG}.tar.xz"
  if wget -q -O "nautilus-${NAUTILUS_TAG}.tar.xz" "${TARBALL_URL}"; then
    tar -xf "nautilus-${NAUTILUS_TAG}.tar.xz"
    mv "nautilus-${NAUTILUS_TAG}" nautilus
  else
    git clone --depth 1 --branch "${NAUTILUS_TAG}" \
      https://gitlab.gnome.org/GNOME/nautilus.git \
      || git clone --depth 1 https://gitlab.gnome.org/GNOME/nautilus.git
    cd nautilus
    git fetch --tags --depth 1 2>/dev/null || true
    git checkout "${NAUTILUS_TAG}" 2>/dev/null \
      || git checkout "refs/tags/${NAUTILUS_TAG}" 2>/dev/null \
      || git checkout "origin/${NAUTILUS_TAG}" 2>/dev/null \
      || echo "AVISO: usando branch default do clone"
    cd "${BUILD_ROOT}"
  fi

  cd "${BUILD_ROOT}/nautilus"
  BRAND="${PRODUCT_DIR}/forks/nautilus/apply-branding.sh"
  if [[ -f "${BRAND}" ]]; then
    chmod +x "${BRAND}"
    bash "${BRAND}" "$(pwd)"
  fi

  log "meson setup (prefix=${PREFIX})"
  meson setup build --prefix="${PREFIX}" -Dtests=false
  log "meson compile -j${NINJA_JOBS}"
  meson compile -C build -j "${NINJA_JOBS}"

  STAGE="${BUILD_ROOT}/stage"
  rm -rf "${STAGE}"
  DESTDIR="${STAGE}" meson install -C build

  NAU_BIN="${STAGE}${PREFIX}/bin/nautilus"
  FD_BIN="${STAGE}${PREFIX}/bin/foliodrive-files"
  if [[ -x "${NAU_BIN}" ]]; then
    mv "${NAU_BIN}" "${FD_BIN}"
  elif [[ ! -x "${FD_BIN}" ]]; then
    echo "Binário nautilus/foliodrive-files ausente após install"
    find "${STAGE}${PREFIX}/bin" -type f 2>/dev/null || true
    return 1
  fi

  # Garantir ELF (não script)
  if file "${FD_BIN}" | grep -qi 'shell script\|ASCII text\|UTF-8'; then
    echo "ERRO: foliodrive-files ainda é script (wrapper). Abortando."
    return 1
  fi

  mkdir -p "${BUNDLE_DIR}"
  tar -czf "${BUNDLE_DIR}/${TARBALL_NAME}" -C "${STAGE}" opt/foliodrive
  log "Tarball (meson): ${BUNDLE_DIR}/${TARBALL_NAME}"
  file "${FD_BIN}"
  ls -lh "${BUNDLE_DIR}/${TARBALL_NAME}"
}

if _build_meson; then
  echo "Build meson OK — fork Nautilus pinado"
else
  log "Build meson falhou"
  if [[ "${USE_APT_FALLBACK}" == "1" ]]; then
    log "Tentando fallback apt (NÃO muda app-id — só debug)…"
    exec "${PRODUCT_DIR}/scripts/build-foliodrive-files-apt.sh"
  fi
  echo "Falha: sem tarball de fork. Corrija o build (USE_APT_FALLBACK=0 no produto)."
  exit 1
fi

echo "Rode: ./scripts/update-versions.sh && ./scripts/build-bundle.sh"
