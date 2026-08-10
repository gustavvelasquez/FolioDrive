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
    p = bundle_dir / comp["file"]
    if p.is_file():
        comp["sha256"] = sha256(p)
        print(f"{key}: {comp['sha256'][:16]}...")
    else:
        print(f"AUSENTE: {p}")

if not data.get("released_at"):
    data["released_at"] = date.today().isoformat()

data["release_notes_url"] = "https://github.com/gustavvelasquez/FolioDrive/releases/tag/v0.1.0"

text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
versions_path.write_text(text, encoding="utf-8")
(bundle_dir / "VERSIONS.json").write_text(text, encoding="utf-8")
print("OK")
