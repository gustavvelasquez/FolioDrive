#!/usr/bin/env bash
# Build Nautilus fork → foliodrive-files tarball (Ubuntu 24.04, maintainer).
# Se meson falhar, usa build-foliodrive-files-apt.sh automaticamente.
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
BUILD_ROOT="${BUILD_ROOT:-/tmp/foliodrive-nautilus-build}"
NAUTILUS_TAG="${NAUTILUS_TAG:-46.0}"
PREFIX="/opt/foliodrive"
TARBALL_NAME="foliodrive-files-46.0-foliodrive.1.tar.gz"
USE_APT_FALLBACK="${USE_APT_FALLBACK:-auto}"

log() { printf '\n==> %s\n' "$*"; }

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Não rode como root."
  exit 1
fi

if [[ "${USE_APT_FALLBACK}" == "1" ]]; then
  exec "${PRODUCT_DIR}/scripts/build-foliodrive-files-apt.sh"
fi

_build_meson() {
  log "Dependências de build (meson)"
  sudo apt-get update -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential meson ninja-build pkg-config git \
    libglib2.0-dev libgtk-4-dev libadwaita-1-dev \
    libportal-dev libportal-gtk4-dev \
    libgexiv2-dev libcloudproviders-dev libcue-dev \
    libxml2-dev libsqlite3-dev \
    python3-nautilus libnautilus-extension-dev \
    gettext

  rm -rf "${BUILD_ROOT}"
  mkdir -p "${BUILD_ROOT}"
  cd "${BUILD_ROOT}"

  if [[ -d nautilus ]]; then
    rm -rf nautilus
  fi
  git clone --depth 1 --branch "${NAUTILUS_TAG}" \
    https://gitlab.gnome.org/GNOME/nautilus.git 2>/dev/null \
    || git clone --depth 1 https://gitlab.gnome.org/GNOME/nautilus.git

  cd nautilus
  git fetch --tags --depth 1 2>/dev/null || true
  git checkout "${NAUTILUS_TAG}" 2>/dev/null \
    || git checkout "refs/tags/${NAUTILUS_TAG}" 2>/dev/null \
    || git checkout "origin/${NAUTILUS_TAG}" 2>/dev/null \
    || echo "AVISO: usando branch default do clone"

  BRAND="${PRODUCT_DIR}/forks/nautilus/apply-branding.sh"
  if [[ -f "${BRAND}" ]]; then
    chmod +x "${BRAND}"
    bash "${BRAND}" "$(pwd)"
  fi

  meson setup build --prefix="${PREFIX}" -Dtests=false
  meson compile -C build

  STAGE="${BUILD_ROOT}/stage"
  rm -rf "${STAGE}"
  DESTDIR="${STAGE}" meson install -C build

  NAU_BIN="${STAGE}${PREFIX}/bin/nautilus"
  FD_BIN="${STAGE}${PREFIX}/bin/foliodrive-files"
  if [[ -x "${NAU_BIN}" ]]; then
    mv "${NAU_BIN}" "${FD_BIN}"
  elif [[ ! -x "${FD_BIN}" ]]; then
    return 1
  fi

  mkdir -p "${BUNDLE_DIR}"
  tar -czf "${BUNDLE_DIR}/${TARBALL_NAME}" -C "${STAGE}" opt/foliodrive
  log "Tarball (meson): ${BUNDLE_DIR}/${TARBALL_NAME}"
}

if _build_meson; then
  echo "Build meson OK"
else
  log "Build meson falhou"
  if [[ "${USE_APT_FALLBACK}" == "0" ]]; then
    exit 1
  fi
  log "Tentando fallback apt…"
  exec "${PRODUCT_DIR}/scripts/build-foliodrive-files-apt.sh"
fi

echo "Rode: ./scripts/update-versions.sh && ./scripts/build-bundle.sh"
