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

# Tarball gerado em host sem +x: forçar permissão após extrair
if [[ -f "${FOLIODRIVE_BIN}" ]]; then
  sudo_run chmod 755 "${FOLIODRIVE_BIN}"
elif [[ -f "${FOLIODRIVE_PREFIX}/bin/nautilus" ]]; then
  sudo_run mv "${FOLIODRIVE_PREFIX}/bin/nautilus" "${FOLIODRIVE_BIN}"
  sudo_run chmod 755 "${FOLIODRIVE_BIN}"
fi

if [[ ! -f "${FOLIODRIVE_BIN}" ]]; then
  echo "Arquivo ausente: ${FOLIODRIVE_BIN}"
  echo "Conteúdo de ${FOLIODRIVE_PREFIX}/bin (se existir):"
  ls -la "${FOLIODRIVE_PREFIX}/bin" 2>/dev/null || echo "(diretório inexistente)"
  exit 1
fi

sudo_run chmod 755 "${FOLIODRIVE_BIN}"

# Schemas / ícones do fork
if [[ -d "${FOLIODRIVE_PREFIX}/share/glib-2.0/schemas" ]]; then
  sudo_run glib-compile-schemas "${FOLIODRIVE_PREFIX}/share/glib-2.0/schemas" 2>/dev/null || true
fi
if [[ -d "${FOLIODRIVE_PREFIX}/share/icons/hicolor" ]]; then
  sudo_run gtk4-update-icon-cache -q -t -f "${FOLIODRIVE_PREFIX}/share/icons/hicolor" 2>/dev/null \
    || sudo_run gtk-update-icon-cache -q -t -f "${FOLIODRIVE_PREFIX}/share/icons/hicolor" 2>/dev/null \
    || true
fi

# ELF do fork — NÃO chamar /usr/bin/nautilus
sudo_run tee "${FOLIODRIVE_WRAPPER}" >/dev/null <<'WRAP'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="/opt/foliodrive/lib/x86_64-linux-gnu:/opt/foliodrive/lib:${LD_LIBRARY_PATH:-}"
export XDG_DATA_DIRS="/opt/foliodrive/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GSETTINGS_SCHEMA_DIR="/opt/foliodrive/share/glib-2.0/schemas${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
exec /opt/foliodrive/bin/foliodrive-files "$@"
WRAP
sudo_run chmod 755 "${FOLIODRIVE_WRAPPER}"

# Exigir ELF (segundo gerenciador real)
if file "${FOLIODRIVE_BIN}" | grep -qi 'shell script\|ASCII text'; then
  echo "ERRO: ${FOLIODRIVE_BIN} ainda é script wrapper — pacote inválido."
  exit 1
fi

sudo_run install -m 644 "${BUNDLE_DIR}/com.foliodrive.Files.desktop" \
  /usr/share/applications/com.foliodrive.Files.desktop
sudo_run update-desktop-database /usr/share/applications/ 2>/dev/null || true

echo "foliodrive-files OK (ELF): ${FOLIODRIVE_BIN}"
echo "atalho: ${FOLIODRIVE_WRAPPER}"
