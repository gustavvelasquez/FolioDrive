#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd sudo

log "Extensão SeaDrive só no prefix FolioDrive (não no Arquivos do SO)"

ext_file="$(read_versions_field components.seadrive_extension.file)"
sudo_run mkdir -p "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions"
sudo_run cp -f "${BUNDLE_DIR}/${ext_file}" \
  "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions/seadrive_extension.py"

sudo_run find "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions" \
  -name 'seadrive_extension*.pyc' -delete 2>/dev/null || true
sudo_run rm -rf "${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions/__pycache__" 2>/dev/null || true

# Remover residual do antigo Plano B (extensão no Arquivos do SO via ~/.local)
_local_ext="${HOME}/.local/share/nautilus-python/extensions"
if [[ -d "${_local_ext}" ]]; then
  rm -f "${_local_ext}"/seadrive_extension.py \
    "${_local_ext}"/seadrive_extension*.pyc 2>/dev/null || true
  rm -rf "${_local_ext}/__pycache__" 2>/dev/null || true
  echo "Limpeza: residual ~/.local seadrive_extension removido (só FolioDrive)."
fi

icons_src="${BUNDLE_DIR}/data/icons"
if [[ -d "${icons_src}" ]]; then
  sudo_run mkdir -p "${FOLIODRIVE_PREFIX}/share/icons/hicolor"
  sudo_run cp -a "${icons_src}/." "${FOLIODRIVE_PREFIX}/share/icons/hicolor/"
  sudo_run gtk-update-icon-cache -f "${FOLIODRIVE_PREFIX}/share/icons/hicolor" 2>/dev/null || true
  # Não copiar para /usr/share — emblemas só via XDG_DATA_DIRS do FolioDrive
fi

echo "Extensão: ${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions/seadrive_extension.py"
