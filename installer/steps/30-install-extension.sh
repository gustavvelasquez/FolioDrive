#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd sudo

log "Extensão SeaDrive no prefix FolioDrive"

ext_file="$(read_versions_field components.seadrive_extension.file)"
sudo_run mkdir -p "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions"
sudo_run cp -f "${BUNDLE_DIR}/${ext_file}" \
  "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions/seadrive_extension.py"

# Plano B: nautilus-python também lê ~/.local (garante menus com wrapper → /usr/bin/nautilus)
mkdir -p "${HOME}/.local/share/nautilus-python/extensions"
cp -f "${BUNDLE_DIR}/${ext_file}" \
  "${HOME}/.local/share/nautilus-python/extensions/seadrive_extension.py"
rm -f "${HOME}/.local/share/nautilus-python/extensions/seadrive_extension"*.pyc 2>/dev/null || true
rm -rf "${HOME}/.local/share/nautilus-python/extensions/__pycache__" 2>/dev/null || true
sudo_run find "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions" \
  -name 'seadrive_extension*.pyc' -delete 2>/dev/null || true
sudo_run rm -rf "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions/__pycache__" 2>/dev/null || true

icons_src="${BUNDLE_DIR}/data/icons"
if [[ -d "${icons_src}" ]]; then
  sudo_run mkdir -p "${FOLIODRIVE_PREFIX}/share/icons/hicolor"
  sudo_run cp -a "${icons_src}/." "${FOLIODRIVE_PREFIX}/share/icons/hicolor/"
  sudo_run gtk-update-icon-cache -f "${FOLIODRIVE_PREFIX}/share/icons/hicolor" 2>/dev/null || true
  sudo_run cp -a "${icons_src}/." /usr/share/icons/hicolor/ 2>/dev/null || true
  sudo_run gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
fi

echo "Extensão: ${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions/seadrive_extension.py"
