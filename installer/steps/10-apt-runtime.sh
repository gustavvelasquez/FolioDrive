#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd sudo

log "Runtime apt (FUSE, python3-nautilus, nautilus…)"
sudo_run apt-get update -y
# libcloudproviders0: exigido pelo ELF do fork (sem isso: exit 127 ao abrir FolioDrive)
sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  python3-nautilus \
  nautilus \
  ca-certificates \
  libportal1 \
  libportal-gtk3-1 \
  libcloudproviders0 \
  || true

if ! dpkg -s libfuse2t64 >/dev/null 2>&1 && ! dpkg -s libfuse2 >/dev/null 2>&1; then
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y libfuse2t64 \
    || sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y libfuse2
fi

if [[ "${SKIP_LIBREOFFICE}" -eq 0 ]]; then
  # Temporário (lab): abrir .xlsx. NÃO faz parte do produto final — será removido.
  log "LibreOffice Calc (temporário — teste .xlsx; será removido do instalador)"
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libreoffice-calc libreoffice-gnome || true
fi

echo "Runtime apt OK"
