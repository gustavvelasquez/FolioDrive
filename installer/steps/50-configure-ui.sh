#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

need_cmd gsettings

log "UI FolioDrive: lista + coluna SeaDrive"

if gsettings list-keys org.gnome.nautilus.preferences >/dev/null 2>&1; then
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
fi

python3 - "${SEADRIVE_COLUMN_NAME}" <<'PY'
import subprocess
import sys

col = sys.argv[1]

def get(key: str) -> list:
    out = subprocess.check_output(
        ["gsettings", "get", "org.gnome.nautilus.list-view", key],
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
        ["gsettings", "set", "org.gnome.nautilus.list-view", key, rendered]
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
print("coluna=%s" % col)
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
