#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd sudo
need_cmd tar

log "Instalar foliodrive-files em ${FOLIODRIVE_PREFIX}"

tarball="$(read_versions_field components.foliodrive_files.file)"
tar_path="${BUNDLE_DIR}/${tarball}"

sudo_run mkdir -p "$(dirname "${FOLIODRIVE_PREFIX}")"
sudo_run tar -xzf "${tar_path}" -C /

if [[ ! -x "${FOLIODRIVE_BIN}" ]] && [[ -x "${FOLIODRIVE_PREFIX}/bin/nautilus" ]]; then
  sudo_run mv "${FOLIODRIVE_PREFIX}/bin/nautilus" "${FOLIODRIVE_BIN}"
fi

if [[ ! -x "${FOLIODRIVE_BIN}" ]]; then
  echo "Binário não encontrado: ${FOLIODRIVE_BIN}"
  exit 1
fi

sudo_run tee "${FOLIODRIVE_WRAPPER}" >/dev/null <<'WRAP'
#!/usr/bin/env bash
export XDG_DATA_DIRS="/opt/foliodrive/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
exec /opt/foliodrive/bin/foliodrive-files "$@"
WRAP
sudo_run chmod 755 "${FOLIODRIVE_WRAPPER}"

sudo_run install -m 644 "${BUNDLE_DIR}/com.foliodrive.Files.desktop" \
  /usr/share/applications/com.foliodrive.Files.desktop
sudo_run update-desktop-database /usr/share/applications/ 2>/dev/null || true

echo "foliodrive-files OK: ${FOLIODRIVE_WRAPPER}"
