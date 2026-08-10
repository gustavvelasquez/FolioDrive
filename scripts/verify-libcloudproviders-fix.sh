#!/usr/bin/env bash
# Pós-fix: instala libcloudproviders0 e retesta launch (debug session ff43e4).
set -u
OUT="${HOME}/debug-ff43e4.log"
SESSION=ff43e4
RUN_ID=post-fix

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
print(f"[{hyp}] {msg}: {data_s[:240]}")
PY
}

echo "123qwe" | sudo -S env DEBIAN_FRONTEND=noninteractive apt-get install -y libcloudproviders0

MISSING="$(ldd /opt/foliodrive/bin/foliodrive-files 2>&1 | grep 'not found' || true)"
log A "verify-fix:ldd" "ldd_after_apt" \
  "$(python3 -c "import json; print(json.dumps({'missing':'''${MISSING}'''.strip().splitlines(),'has_so':__import__('os').path.exists('/usr/lib/x86_64-linux-gnu/libcloudproviders.so.0')}))")"

export LD_LIBRARY_PATH="/opt/foliodrive/lib/x86_64-linux-gnu:/opt/foliodrive/lib:${LD_LIBRARY_PATH:-}"
export XDG_DATA_DIRS="/opt/foliodrive/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GSETTINGS_SCHEMA_DIR="/opt/foliodrive/share/glib-2.0/schemas${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
if [[ -S "${XDG_RUNTIME_DIR}/wayland-0" ]]; then
  export WAYLAND_DISPLAY=wayland-0
fi
if [[ -z "${DISPLAY:-}" && -S /tmp/.X11-unix/X0 ]]; then
  export DISPLAY=:0
fi

ERRF="$(mktemp)"
set +e
timeout 8s /usr/local/bin/foliodrive-files "${HOME}/SeaDrive" >"$ERRF" 2>&1
RC=$?
set -e
ERR="$(head -c 4000 "$ERRF" | tr '\n' ' | ')"
rm -f "$ERRF"

log A "verify-fix:launch" "launch_after_apt" \
  "$(python3 -c "import json; print(json.dumps({'rc':${RC},'display':'${DISPLAY:-}','wayland':'${WAYLAND_DISPLAY:-}','stderr_head':'${ERR}'}))")"

echo "Log: ${OUT}"
tail -n 5 "$OUT"
