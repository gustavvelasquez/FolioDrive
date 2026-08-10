#!/usr/bin/env bash
# Promove product/ (lab) → repo FolioDrive (produção). Não copia blobs do bundle.
set -euo pipefail

LAB_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PRODUCT="${LAB_ROOT}/product"
PROD_ROOT="${PROD_ROOT:-${LAB_ROOT}/../FolioDrive}"

if [[ ! -d "${PRODUCT}" ]]; then
  echo "Ausente: ${PRODUCT}"
  exit 1
fi

mkdir -p "${PROD_ROOT}"

rsync -a --delete \
  --exclude 'bundle/*.AppImage' \
  --exclude 'bundle/*.tar.gz' \
  --exclude 'bundle/*.run' \
  --exclude 'bundle/seadrive_extension.py' \
  --exclude 'bundle/data/' \
  "${PRODUCT}/" "${PROD_ROOT}/"

for f in LICENSE NOTICE README.md; do
  if [[ -f "${LAB_ROOT}/product/${f}" ]]; then
    cp -f "${LAB_ROOT}/product/${f}" "${PROD_ROOT}/${f}"
  fi
done

# Raiz do repo produção = conteúdo de product (installer, scripts, etc.)
if [[ -f "${PROD_ROOT}/product/README.md" ]]; then
  : # already flat if rsync product/ to PROD_ROOT
fi

echo "Promovido para: ${PROD_ROOT}"
echo "Próximo: cd ${PROD_ROOT} && git add -A && git commit && git push"
echo "Anexe blobs pinados no GitHub Release (não no git)."
