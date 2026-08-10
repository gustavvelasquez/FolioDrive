#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

log "Pré-check FolioDrive"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Não rode o instalador como root. Use sudo apenas quando pedido."
  exit 1
fi

if [[ ! -f "${VERSIONS_FILE}" ]]; then
  echo "Ausente: ${VERSIONS_FILE}"
  exit 1
fi

arch="$(uname -m)"
if [[ "${arch}" != "x86_64" ]]; then
  echo "Arquitetura não suportada: ${arch} (esperado x86_64)"
  exit 1
fi

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "AVISO: testado em Ubuntu 24.04 GNOME; detectado: ${ID:-desconhecido}"
  fi
  if [[ "${VERSION_ID:-}" != "24.04" ]]; then
    echo "AVISO: FolioDrive 0.1.0 alvo Ubuntu 24.04; detectado ${VERSION_ID:-?}"
  fi
fi

desk="${XDG_CURRENT_DESKTOP:-}"
if [[ -n "${desk}" ]] && [[ "${desk}" != *GNOME* ]] && [[ "${desk}" != *ubuntu* ]] && [[ "${desk}" != *Ubuntu* ]]; then
  echo "AVISO: sessão ${desk} — recomendado GNOME/Ubuntu Desktop."
fi

for key in seadrive_appimage foliodrive_files seadrive_extension; do
  fname="$(read_versions_field "components.${key}.file")"
  fpath="${BUNDLE_DIR}/${fname}"
  if [[ ! -f "${fpath}" ]]; then
    echo "Blob ausente no bundle: ${fpath}"
    echo "O maintainer deve rodar product/scripts/build-bundle.sh antes do release."
    exit 1
  fi
  expected="$(read_versions_field "components.${key}.sha256")"
  verify_checksum "${fpath}" "${expected}"
done

icons_dir="${BUNDLE_DIR}/data/icons"
if [[ ! -d "${icons_dir}" ]]; then
  echo "AVISO: ${icons_dir} ausente — emblemas podem faltar."
fi

if [[ ! -f "${BUNDLE_DIR}/com.foliodrive.Files.desktop" ]]; then
  echo "Ausente: ${BUNDLE_DIR}/com.foliodrive.Files.desktop"
  exit 1
fi

echo "Pré-check OK — product_version=$(read_versions_field product_version)"
