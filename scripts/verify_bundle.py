import hashlib
import json
import sys
from pathlib import Path

product = Path(sys.argv[1])
bundle = product / "bundle"
versions = json.loads((bundle / "VERSIONS.json").read_text(encoding="utf-8"))


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


ok = True
for key, comp in versions["components"].items():
    p = bundle / comp["file"]
    if not p.is_file():
        print(f"FALHA: ausente {p.name}")
        ok = False
        continue
    got = sha256(p)
    exp = comp.get("sha256") or ""
    if not exp:
        print(f"AVISO: sha256 vazio para {p.name}")
    elif got != exp:
        print(f"FALHA: checksum {p.name}")
        ok = False
    else:
        print(f"OK: {p.name}")

for extra in ("com.foliodrive.Files.desktop",):
    if not (bundle / extra).is_file():
        print(f"FALHA: ausente {extra}")
        ok = False

if not ok:
    sys.exit(1)
print("verify-bundle: OK")
