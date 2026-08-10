#!/usr/bin/env bash
# Instala FolioDrive: SeaDrive pinado + Nautilus fork + extensão.
#
# Uso (Ubuntu 24.04 GNOME, com bundle/ preenchido):
#   cd product
#   chmod +x installer/install-foliodrive.sh
#   ./installer/install-foliodrive.sh
#
# Requer: bundle/VERSIONS.json + blobs pinados (ver bundle/README.md).
# Não baixa nada de seafile.com / GNOME upstream.

set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${INSTALLER_DIR}/common.sh"
STEPS_DIR="${INSTALLER_DIR}/steps"

usage() {
  cat <<EOF
Uso: $0 [opções]

  --skip-libreoffice   Não instala LibreOffice Calc
  --no-autostart       Não cria autostart do SeaDrive
  --start              Tenta iniciar SeaDrive ao fim (precisa GUI)
  -h, --help           Ajuda

Bundle: ${BUNDLE_DIR}
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-libreoffice) SKIP_LIBREOFFICE=1; shift ;;
    --no-autostart) NO_AUTOSTART=1; shift ;;
    --start) START_SEADRIVE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1"; usage; exit 1 ;;
  esac
done

export SKIP_LIBREOFFICE NO_AUTOSTART START_SEADRIVE

run_step() {
  local step="$1"
  if [[ ! -f "${step}" ]]; then
    echo "Passo ausente: ${step}"
    exit 1
  fi
  chmod +x "${step}" 2>/dev/null || true
  bash "${step}"
}

run_step "${STEPS_DIR}/00-pre-check.sh"
run_step "${STEPS_DIR}/10-apt-runtime.sh"
run_step "${STEPS_DIR}/20-install-foliodrive-files.sh"
run_step "${STEPS_DIR}/30-install-extension.sh"
run_step "${STEPS_DIR}/40-install-seadrive.sh"
run_step "${STEPS_DIR}/50-configure-ui.sh"
run_step "${STEPS_DIR}/60-desktop-foliodrive.sh"

pv="$(read_versions_field product_version)"

cat <<EOF

============================================================
FolioDrive ${pv} — instalação OK
============================================================
SeaDrive:     ${APPIMAGE_PATH}
Gerenciador:  foliodrive-files → ${FOLIODRIVE_PREFIX}
Extensão:     ${FOLIODRIVE_PREFIX}/share/nautilus-python/extensions/

Próximos passos (manual):
  1. Abra SeaDrive (menu ou bandeja)
  2. Login no seu servidor Seafile
  3. Abra FolioDrive em ~/SeaDrive
  4. Teste Free up space / Always keep e coluna SeaDrive

Lixeira: só na web Seafile (fora do 1º release).
EOF
