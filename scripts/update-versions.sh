#!/usr/bin/env bash
# Preenche sha256 em VERSIONS.json e copia para bundle/VERSIONS.json
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSIONS="${PRODUCT_DIR}/VERSIONS.json"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
BUNDLE_VERSIONS="${BUNDLE_DIR}/VERSIONS.json"

python3 - "${VERSIONS}" "${BUNDLE_DIR}" <<'PY'
import hashlib
import json
import sys
from datetime import date
from pathlib import Path

versions_path = Path(sys.argv[1])
bundle_dir = Path(sys.argv[2])

data = json.loads(versions_path.read_text(encoding="utf-8"))

def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

for key, comp in data["components"].items():
    fpath = bundle_dir / comp["file"]
    if fpath.is_file():
        comp["sha256"] = sha256(fpath)
        print(f"{key}: {comp['file']} -> {comp['sha256'][:16]}…")
    else:
        print(f"AVISO: ausente {fpath}")

if not data.get("released_at"):
    data["released_at"] = date.today().isoformat()

versions_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
bundle_dir.mkdir(parents=True, exist_ok=True)
bundle_dir.joinpath("VERSIONS.json").write_text(
    json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
)
print(f"Atualizado: {versions_path} e {bundle_dir / 'VERSIONS.json'}")
PY
