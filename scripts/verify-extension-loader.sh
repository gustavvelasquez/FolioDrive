#!/usr/bin/env bash
# Pós-fix extensão: confirma loader + journal (session ff43e4)
set -u
OUT="${HOME}/debug-ff43e4.log"
EXT_DIR="/opt/foliodrive/lib/x86_64-linux-gnu/nautilus/extensions-4"
python3 - "$OUT" "$EXT_DIR" <<'PY'
import json, os, sys, time, subprocess
out, ext_dir = sys.argv[1:3]
so = os.path.join(ext_dir, "libnautilus-python.so")
j = subprocess.check_output(
    ["journalctl", "--user", "-n", "80", "--no-pager"],
    text=True, errors="replace",
)
hits = [ln for ln in j.splitlines() if any(
    k in ln for k in ("SeaDrive", "nautilus-python", "seadrive_extension", "GtkStack", "foliodrive-files")
)][-25:]
rec = {
  "sessionId": "ff43e4",
  "runId": "ext-post-fix",
  "hypothesisId": "F",
  "location": "verify-extension-loader",
  "message": "loader_installed_and_journal",
  "data": {
    "has_so": os.path.isfile(so),
    "so_size": os.path.getsize(so) if os.path.isfile(so) else -1,
    "alive": int(subprocess.getoutput("pgrep -c -f /opt/foliodrive/bin/foliodrive-files") or "0"),
    "journal_hits": hits,
  },
  "timestamp": int(time.time() * 1000),
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(rec, ensure_ascii=False) + "\n")
print(json.dumps(rec, ensure_ascii=False, indent=2))
PY
