#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

log "SeaDrive AppImage pinado"

appimage_file="$(read_versions_field components.seadrive_appimage.file)"
src="${BUNDLE_DIR}/${appimage_file}"

mkdir -p "${APP_DIR}"
cp -f "${src}" "${APPIMAGE_PATH}"
chmod +x "${APPIMAGE_PATH}"
ln -sfn "${APPIMAGE_PATH}" "${APP_DIR}/SeaDrive.AppImage"

mkdir -p "${HOME}/.local/share/applications" "${HOME}/.config/autostart"
cat > "${DESKTOP_SEADRIVE}" <<EOF
[Desktop Entry]
Name=SeaDrive
Comment=Seafile Drive (FolioDrive bundle)
Exec=env DESKTOP_SESSION=gnome ${APPIMAGE_PATH}
Icon=folder-remote
Type=Application
Categories=Network;FileTransfer;
StartupNotify=true
Terminal=false
EOF
chmod +x "${DESKTOP_SEADRIVE}"
update-desktop-database "${HOME}/.local/share/applications/" 2>/dev/null || true

if [[ "${NO_AUTOSTART}" -eq 0 ]]; then
  cp -f "${DESKTOP_SEADRIVE}" "${DESKTOP_SEADRIVE_AUTO}"
fi

if [[ "${START_SEADRIVE}" -eq 1 ]]; then
  log "Iniciando SeaDrive…"
  if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    nohup env DESKTOP_SESSION=gnome "${APPIMAGE_PATH}" >/tmp/seadrive-foliodrive.log 2>&1 &
    sleep 2
    echo "Log: /tmp/seadrive-foliodrive.log"
  else
    echo "Sem DISPLAY — inicie pelo menu Aplicativos → SeaDrive."
  fi
fi

echo "AppImage OK: ${APPIMAGE_PATH}"
