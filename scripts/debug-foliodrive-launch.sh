#!/usr/bin/env bash
# Diagnóstico: FolioDrive não abre (escreve NDJSON para debug de sessão).
# Uso (na VM Ubuntu, na sessão gráfica):
#   bash ~/FolioDrive/scripts/debug-foliodrive-launch.sh
# ou copie este arquivo e rode.
set -u
OUT="${HOME}/debug-ff43e4.log"
SESSION="ff43e4"
RUN_ID="${RUN_ID:-pre-fix}"
mkdir -p "$(dirname "$OUT")"
: > "$OUT"

log() {
  local hyp="$1" loc="$2" msg="$3" data="$4"
  python3 - "$OUT" "$SESSION" "$RUN_ID" "$hyp" "$loc" "$msg" "$data" <<'PY'
import json, sys, time
out, session, run_id, hyp, loc, msg, data_s = sys.argv[1:8]
try:
    data = json.loads(data_s)
except Exception:
    data = {"raw": data_s}
rec = {
    "sessionId": session,
    "runId": run_id,
    "hypothesisId": hyp,
    "location": loc,
    "message": msg,
    "data": data,
    "timestamp": int(time.time() * 1000),
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(rec, ensure_ascii=False) + "\n")
print(f"[{hyp}] {msg}: {data_s[:200]}")
PY
}

WRAP="/usr/local/bin/foliodrive-files"
BIN="/opt/foliodrive/bin/foliodrive-files"
DESK="${HOME}/.local/share/applications/com.foliodrive.Files.desktop"

# H-A: libs ausentes
missing="$(ldd "$BIN" 2>&1 | grep 'not found' || true)"
log A "debug-foliodrive-launch.sh:ldd" "ldd_missing" \
  "$(python3 -c "import json; print(json.dumps({'missing':'''${missing}'''.strip().splitlines(),'file':'''$(file -b "$BIN" 2>/dev/null || echo '?')'''}))")"

# H-B: wrapper / desktop / SeaDrive path
wrap_head="$(head -20 "$WRAP" 2>/dev/null || echo MISSING)"
desk_exec="$(grep -E '^Exec=' "$DESK" 2>/dev/null || echo MISSING)"
log B "debug-foliodrive-launch.sh:paths" "wrapper_desktop_paths" \
  "$(python3 -c "import json,os; print(json.dumps({'wrap_exists':os.path.isfile('$WRAP'),'wrap_size':os.path.getsize('$WRAP') if os.path.isfile('$WRAP') else -1,'wrap_head':'''${wrap_head}'''.replace('\n',' | '),'desk_exec':'''${desk_exec}''','seadrive_exists':os.path.isdir(os.path.expanduser('~/SeaDrive')),'home':os.path.expanduser('~')}))")"

# H-C: schemas / resources
schemas="$(ls /opt/foliodrive/share/glib-2.0/schemas 2>/dev/null | tr '\n' ' ')"
gset="$(GSETTINGS_SCHEMA_DIR=/opt/foliodrive/share/glib-2.0/schemas gsettings list-keys com.foliodrive.files.preferences 2>&1 | head -3 | tr '\n' ';')"
log C "debug-foliodrive-launch.sh:schemas" "schemas_and_gsettings" \
  "$(python3 -c "import json; print(json.dumps({'schemas':'${schemas}','gsettings_sample':'${gset}','gschema_compiled':__import__('os').path.isfile('/opt/foliodrive/share/glib-2.0/schemas/gschemas.compiled')}))")"

# H-D/E: launch with DISPLAY and capture exit + stderr
export LD_LIBRARY_PATH="/opt/foliodrive/lib/x86_64-linux-gnu:/opt/foliodrive/lib:${LD_LIBRARY_PATH:-}"
export XDG_DATA_DIRS="/opt/foliodrive/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GSETTINGS_SCHEMA_DIR="/opt/foliodrive/share/glib-2.0/schemas${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"

# Prefer user graphical session display
if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
  if [[ -S /run/user/$(id -u)/wayland-0 ]]; then
    export WAYLAND_DISPLAY=wayland-0
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
  elif [[ -S /tmp/.X11-unix/X0 ]]; then
    export DISPLAY=:0
  fi
fi

ERRF="$(mktemp)"
set +e
timeout 8s "$BIN" "${HOME}/SeaDrive" >"$ERRF" 2>&1
RC=$?
set -e
ERR="$(head -c 4000 "$ERRF" | tr '\n' ' | ')"
rm -f "$ERRF"

log D "debug-foliodrive-launch.sh:launch" "launch_result" \
  "$(python3 -c "import json,os; print(json.dumps({'rc':$RC,'display':os.environ.get('DISPLAY',''),'wayland':os.environ.get('WAYLAND_DISPLAY',''),'xdg_runtime':os.environ.get('XDG_RUNTIME_DIR',''),'stderr_head':'''${ERR}'''}))")"

# H-E: also try without path arg (home)
ERRF="$(mktemp)"
set +e
timeout 8s "$BIN" >"$ERRF" 2>&1
RC2=$?
set -e
ERR2="$(head -c 2000 "$ERRF" | tr '\n' ' | ')"
rm -f "$ERRF"
log E "debug-foliodrive-launch.sh:launch_nopath" "launch_without_seadrive_path" \
  "$(python3 -c "import json; print(json.dumps({'rc':$RC2,'stderr_head':'''${ERR2}'''}))")"

echo ""
echo "Log escrito em: $OUT"
echo "Copie esse arquivo para o PC Windows no workspace StorageOneDriveLike como debug-ff43e4.log"
echo "ou informe o IP da VM para o agente buscar via SCP."
