#!/usr/bin/env bash
# Pipeline completo do maintainer (Ubuntu 24.04 GNOME).
set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${PRODUCT_DIR}"

chmod +x scripts/*.sh forks/nautilus/apply-branding.sh 2>/dev/null || true
chmod +x installer/install-foliodrive.sh installer/steps/*.sh 2>/dev/null || true

echo "=== 1/5 fetch SeaDrive ==="
./scripts/fetch-seadrive.sh

echo "=== 2/5 build foliodrive-files ==="
./scripts/build-foliodrive-files.sh

echo "=== 3/5 build bundle (extensão) ==="
./scripts/build-bundle.sh

echo "=== 4/5 update VERSIONS sha256 ==="
./scripts/update-versions.sh

echo "=== 5/5 package release ==="
./scripts/package-release.sh

echo ""
echo "OK. Teste: ./installer/install-foliodrive.sh"
echo "Release: dist/FolioDrive-*-installer.tar.gz"
