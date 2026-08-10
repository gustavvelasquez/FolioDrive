#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd gsettings

log "UI FolioDrive: lista + coluna SeaDrive (schemas com.foliodrive.files.*)"

PREF_SCHEMA="com.foliodrive.files.preferences"
LIST_SCHEMA="com.foliodrive.files.list-view"

# Garante schemas do fork compilados / visíveis (install DESTDIR às vezes pula compile)
if [[ -d "${FOLIODRIVE_PREFIX}/share/glib-2.0/schemas" ]]; then
  sudo_run glib-compile-schemas "${FOLIODRIVE_PREFIX}/share/glib-2.0/schemas" 2>/dev/null || true
fi
export GSETTINGS_SCHEMA_DIR="${FOLIODRIVE_PREFIX}/share/glib-2.0/schemas${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
export XDG_DATA_DIRS="${FOLIODRIVE_PREFIX}/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

if ! gsettings list-keys "${PREF_SCHEMA}" >/dev/null 2>&1; then
  echo "ERRO: schema ${PREF_SCHEMA} ausente."
  echo "O FolioDrive (fork) precisa estar instalado em ${FOLIODRIVE_PREFIX}."
  echo "Não configuramos org.gnome.nautilus.* (evita alterar o Arquivos do Ubuntu)."
  exit 1
fi
if ! gsettings list-keys "${LIST_SCHEMA}" >/dev/null 2>&1; then
  echo "ERRO: schema ${LIST_SCHEMA} ausente."
  exit 1
fi

gsettings set "${PREF_SCHEMA}" default-folder-viewer 'list-view'

python3 - "${SEADRIVE_COLUMN_NAME}" "${LIST_SCHEMA}" <<'PY'
import subprocess
import sys

col = sys.argv[1]
list_schema = sys.argv[2]

def get(key: str) -> list:
    out = subprocess.check_output(
        ["gsettings", "get", list_schema, key],
        text=True,
    ).strip()
    if out in ("@as []", "[]"):
        return []
    out = out.strip("[]")
    parts = []
    for raw in out.split(","):
        raw = raw.strip().strip("'\"")
        if raw:
            parts.append(raw)
    return parts

def set_list(key: str, values) -> None:
    rendered = "[" + ", ".join("'" + v + "'" for v in values) + "]"
    subprocess.check_call(
        ["gsettings", "set", list_schema, key, rendered]
    )

visible = get("default-visible-columns")
order = get("default-column-order")

if not visible:
    visible = ["name", "size", "date_modified"]
if not order:
    order = list(visible)

if col not in visible:
    visible.append(col)
if col not in order:
    order.append(col)

set_list("default-visible-columns", visible)
set_list("default-column-order", order)
print("schema=%s coluna=%s" % (list_schema, col))
PY

_mount="${HOME}/SeaDrive"
if [[ -d "${_mount}" ]] && command -v gio >/dev/null 2>&1; then
  gio set -t string "${_mount}" metadata::nautilus-default-view \
    "OAFIID:Nautilus_File_Manager_List_View" 2>/dev/null || true
fi

if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  foliodrive-files -q 2>/dev/null || true
  echo "FolioDrive reiniciado."
else
  echo "Sem DISPLAY — na GUI: feche e abra FolioDrive."
fi
