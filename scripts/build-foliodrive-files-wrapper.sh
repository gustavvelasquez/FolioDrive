#!/usr/bin/env bash
# DEBUG ONLY — NÃO usar no Release de produto.
# Wrapper chama /usr/bin/nautilus (mesmo app); não entrega 2 gerenciadores.
# Produto: ./scripts/build-foliodrive-files.sh (meson, ELF em /opt/foliodrive).
echo "ERRO: build-foliodrive-files-wrapper.sh é só debug. Use build-foliodrive-files.sh" >&2
exit 1

set -euo pipefail

PRODUCT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="${PRODUCT_DIR}/bundle"
TARBALL_NAME="foliodrive-files-46.0-foliodrive.1.tar.gz"
STAGE="${STAGE:-/tmp/foliodrive-wrapper-stage}"

rm -rf "${STAGE}"
mkdir -p "${STAGE}/opt/foliodrive/bin" "${STAGE}/opt/foliodrive/share"

cat > "${STAGE}/opt/foliodrive/bin/foliodrive-files" <<'WRAP'
#!/usr/bin/env bash
export XDG_DATA_DIRS="/opt/foliodrive/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
if [[ -x /opt/foliodrive/bin/nautilus-real ]]; then
  exec /opt/foliodrive/bin/nautilus-real "$@"
fi
if [[ -x /usr/bin/nautilus ]]; then
  exec /usr/bin/nautilus "$@"
fi
echo "foliodrive-files: nautilus não encontrado. Rode apt install nautilus."
exit 1
WRAP
chmod +x "${STAGE}/opt/foliodrive/bin/foliodrive-files"

mkdir -p "${STAGE}/opt/foliodrive/share/nautilus-python/extensions"
mkdir -p "${BUNDLE_DIR}"
tar -czf "${BUNDLE_DIR}/${TARBALL_NAME}" -C "${STAGE}" opt/foliodrive
echo "Wrapper tarball: ${BUNDLE_DIR}/${TARBALL_NAME}"
