#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

log "Atalho FolioDrive (abre ~/SeaDrive)"

mkdir -p "${HOME}/.local/share/applications"
cat > "${DESKTOP_FOLIODRIVE}" <<EOF
[Desktop Entry]
Name=FolioDrive
Comment=Arquivos na nuvem Seafile
Exec=foliodrive-files ${HOME}/SeaDrive
Icon=folder-remote
Type=Application
Categories=Utility;FileManager;Network;
StartupNotify=true
Terminal=false
EOF
chmod +x "${DESKTOP_FOLIODRIVE}"
update-desktop-database "${HOME}/.local/share/applications/" 2>/dev/null || true

echo "Atalho: ${DESKTOP_FOLIODRIVE}"
