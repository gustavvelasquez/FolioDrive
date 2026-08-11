#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd sudo

log "Runtime apt (FUSE, python3-nautilus, nautilus…)"
sudo_run apt-get update -y

# Críticos para FolioDrive abrir + menus/coluna (não engolir falha com || true)
sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  python3-nautilus \
  nautilus \
  ca-certificates \
  libportal1 \
  libportal-gtk3-1 \
  libcloudproviders0

# Confirma runtime do ELF (sem isso: exit 127 ao abrir)
if ! dpkg -s libcloudproviders0 >/dev/null 2>&1; then
  echo "ERRO: libcloudproviders0 não instalado — FolioDrive não abrirá."
  exit 1
fi
# Confirma loader Python do Nautilus (sem isso: sem menus/coluna no fork)
if [[ ! -f /usr/lib/x86_64-linux-gnu/nautilus/extensions-4/libnautilus-python.so ]] \
  && [[ ! -f /usr/lib/nautilus/extensions-4/libnautilus-python.so ]]; then
  echo "ERRO: libnautilus-python.so ausente — instale python3-nautilus."
  exit 1
fi

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
