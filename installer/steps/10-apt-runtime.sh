#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd sudo

log "Runtime apt (FUSE, python3-nautilus…)"
sudo_run apt-get update -y
sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  python3-nautilus \
  ca-certificates \
  libportal1 \
  libportal-gtk3-1 \
  || true

if ! dpkg -s libfuse2t64 >/dev/null 2>&1 && ! dpkg -s libfuse2 >/dev/null 2>&1; then
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y libfuse2t64 \
    || sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y libfuse2
fi

if [[ "${SKIP_LIBREOFFICE}" -eq 0 ]]; then
  log "LibreOffice Calc (abrir .xlsx)"
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libreoffice-calc libreoffice-gnome || true
fi

echo "Runtime apt OK"
