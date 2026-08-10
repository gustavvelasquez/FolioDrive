#!/usr/bin/env bash
# Paths e funções compartilhados pelo instalador FolioDrive.
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER_DIR="${PRODUCT_DIR}/installer"
BUNDLE_DIR="${BUNDLE_DIR:-${PRODUCT_DIR}/bundle}"
VERSIONS_FILE="${BUNDLE_DIR}/VERSIONS.json"

FOLIODRIVE_PREFIX="/opt/foliodrive"
FOLIODRIVE_BIN="${FOLIODRIVE_PREFIX}/bin/foliodrive-files"
FOLIODRIVE_WRAPPER="/usr/local/bin/foliodrive-files"

SEADRIVE_VERSION="${SEADRIVE_VERSION:-3.0.23}"
APP_DIR="${HOME}/Applications"
APPIMAGE_NAME="SeaDrive-x86_64-${SEADRIVE_VERSION}.AppImage"
APPIMAGE_PATH="${APP_DIR}/${APPIMAGE_NAME}"

DESKTOP_SEADRIVE="${HOME}/.local/share/applications/seadrive.desktop"
DESKTOP_SEADRIVE_AUTO="${HOME}/.config/autostart/seadrive.desktop"
DESKTOP_FOLIODRIVE="${HOME}/.local/share/applications/com.foliodrive.Files.desktop"

SEADRIVE_COLUMN_NAME="${SEADRIVE_COLUMN_NAME:-SeaDriveExt::status}"

SKIP_LIBREOFFICE=0
NO_AUTOSTART=0
START_SEADRIVE=0

log() { printf '\n==> %s\n' "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta comando: $1"
    exit 1
  }
}

sudo_run() {
  if [[ -n "${SUDO_ASKPASS:-}" && -x "${SUDO_ASKPASS}" ]]; then
    sudo -A "$@"
  else
    sudo "$@"
  fi
}

read_versions_field() {
  local jq_path="$1"
  need_cmd python3
  python3 - "${VERSIONS_FILE}" "${jq_path}" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
path = sys.argv[2].split(".")
cur = data
for p in path:
    cur = cur[p]
print(cur)
PY
}

sha256_file() {
  sha256sum "$1" | awk '{print $1}'
}

verify_checksum() {
  local file="$1" expected="$2"
  [[ -n "${expected}" ]] || {
    echo "AVISO: sha256 vazio em VERSIONS.json para $(basename "$file") — pulando verificação (dev)."
    return 0
  }
  local got
  got="$(sha256_file "$file")"
  if [[ "${got}" != "${expected}" ]]; then
    echo "Checksum inválido: $(basename "$file")"
    echo "  esperado: ${expected}"
    echo "  obtido:   ${got}"
    exit 1
  fi
}

export PRODUCT_DIR INSTALLER_DIR BUNDLE_DIR VERSIONS_FILE
export FOLIODRIVE_PREFIX FOLIODRIVE_BIN FOLIODRIVE_WRAPPER
export APP_DIR APPIMAGE_NAME APPIMAGE_PATH
export DESKTOP_SEADRIVE DESKTOP_SEADRIVE_AUTO DESKTOP_FOLIODRIVE
export SEADRIVE_COLUMN_NAME SKIP_LIBREOFFICE NO_AUTOSTART START_SEADRIVE
