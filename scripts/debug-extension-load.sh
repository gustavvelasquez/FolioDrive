#!/usr/bin/env bash
# Debug: menu/coluna SeaDrive + cursor busy (session ff43e4)
set -u
OUT="${HOME}/debug-ff43e4.log"
: > "$OUT"
SESSION=ff43e4
RUN_ID="${RUN_ID:-ext-pre}"

log() {
  python3 - "$OUT" "$SESSION" "$RUN_ID" "$1" "$2" "$3" "$4" <<'PY'
import json, sys, time
out, session, run_id, hyp, loc, msg, data_s = sys.argv[1:8]
try:
    data = json.loads(data_s)
except Exception:
    data = {"raw": data_s}
rec = {
    "sessionId": session, "runId": run_id, "hypothesisId": hyp,
    "location": loc, "message": msg, "data": data,
    "timestamp": int(time.time() * 1000),
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(rec, ensure_ascii=False) + "\n")
print(f"[{hyp}] {msg}")
PY
}

EXT_DIR="/opt/foliodrive/lib/x86_64-linux-gnu/nautilus/extensions-4"
SYS_PY="/usr/lib/x86_64-linux-gnu/nautilus/extensions-4/libnautilus-python.so"
PY_EXT="/opt/foliodrive/share/nautilus-python/extensions/seadrive_extension.py"

# H-F: pasta extensions-4 do fork ausente / sem libnautilus-python.so
has_dir=0; [[ -d "$EXT_DIR" ]] && has_dir=1
has_so=0; [[ -f "$EXT_DIR/libnautilus-python.so" ]] && has_so=1
log F "debug-ext:paths" "fork_extension_loader" \
  "$(python3 -c "import json,os; print(json.dumps({'ext_dir':'$EXT_DIR','has_dir':$has_dir,'has_so':$has_so,'sys_py_exists':os.path.isfile('$SYS_PY'),'py_ext_exists':os.path.isfile('$PY_EXT')}))")"

# H-G: gsettings coluna já configurada (esperado true)
cols="$(GSETTINGS_SCHEMA_DIR=/opt/foliodrive/share/glib-2.0/schemas gsettings get com.foliodrive.files.list-view default-visible-columns 2>&1)"
log G "debug-ext:gsettings" "visible_columns" \
  "$(python3 -c "import json; print(json.dumps({'cols':'''$cols'''}))")"

# Matar instâncias antigas
pkill -f '/opt/foliodrive/bin/foliodrive-files' 2>/dev/null || true
sleep 1

# Aplicar fix provisório (H-F): instalar loader Python no prefix do fork
echo "123qwe" | sudo -S mkdir -p "$EXT_DIR"
echo "123qwe" | sudo -S cp -f "$SYS_PY" "$EXT_DIR/libnautilus-python.so"
# #region agent log
log F "debug-ext:install" "copied_libnautilus_python" \
  "$(python3 -c "import json,os; print(json.dumps({'installed':os.path.isfile('$EXT_DIR/libnautilus-python.so'),'size':os.path.getsize('$EXT_DIR/libnautilus-python.so') if os.path.isfile('$EXT_DIR/libnautilus-python.so') else -1}))")"
# #endregion

# H-H: extensão Python carrega? (NAUTILUS_PYTHON_DEBUG)
export LD_LIBRARY_PATH="/opt/foliodrive/lib/x86_64-linux-gnu:/opt/foliodrive/lib:${LD_LIBRARY_PATH:-}"
export XDG_DATA_DIRS="/opt/foliodrive/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GSETTINGS_SCHEMA_DIR="/opt/foliodrive/share/glib-2.0/schemas${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
export NAUTILUS_PYTHON_DEBUG=misc
export G_MESSAGES_DEBUG=all
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
[[ -S "${XDG_RUNTIME_DIR}/wayland-0" ]] && export WAYLAND_DISPLAY=wayland-0
[[ -z "${DISPLAY:-}" && -S /tmp/.X11-unix/X0 ]] && export DISPLAY=:0

ERRF="$(mktemp)"
set +e
# Lançar via systemd-user (sessão gráfica) e capturar journal curto
systemd-run --user --same-dir \
  --setenv=LD_LIBRARY_PATH="$LD_LIBRARY_PATH" \
  --setenv=XDG_DATA_DIRS="$XDG_DATA_DIRS" \
  --setenv=GSETTINGS_SCHEMA_DIR="$GSETTINGS_SCHEMA_DIR" \
  --setenv=NAUTILUS_PYTHON_DEBUG=misc \
  /usr/local/bin/foliodrive-files "${HOME}/SeaDrive" >"$ERRF" 2>&1
sleep 4
set -e

# Logs do processo
J="$(journalctl --user -n 120 --no-pager 2>/dev/null | grep -iE 'folio|nautilus-python|seadrive|Importing|Loading|extension' | tail -40 | tr '\n' ' | ')"
ALIVE="$(pgrep -c -f '/opt/foliodrive/bin/foliodrive-files' 2>/dev/null || echo 0)"
ERR="$(head -c 3000 "$ERRF" | tr '\n' ' | ')"
rm -f "$ERRF"

log H "debug-ext:launch" "python_debug_after_loader" \
  "$(python3 -c "import json; print(json.dumps({'alive':int('$ALIVE' or 0),'journal_tail':'${J}'[:1500],'stderr_head':'${ERR}'[:800]}))")"

# H-I: busy / tracker
TRK="$(pgrep -af tracker | head -5 | tr '\n' ';')"
log I "debug-ext:tracker" "tracker_and_fuse" \
  "$(python3 -c "import json,os; print(json.dumps({'tracker':'''$TRK''','seadrive_mount':os.path.ismount(os.path.expanduser('~/SeaDrive')) or os.path.isdir(os.path.expanduser('~/SeaDrive/My Libraries'))}))")"

echo "Log: $OUT"
cat "$OUT"
