#!/usr/bin/env bash
# FolioDrive — instalador de um comando.
# Baixa o pacote pinado da Release deste mesmo repositório e instala.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/gustavvelasquez/FolioDrive/main/install.sh | bash
#   # ou:
#   wget -qO install.sh https://raw.githubusercontent.com/gustavvelasquez/FolioDrive/main/install.sh && bash install.sh

set -euo pipefail

REPO="gustavvelasquez/FolioDrive"
VERSION="${FOLIODRIVE_VERSION:-0.1.0}"
TAG="v${VERSION}"
PKG="FolioDrive-${VERSION}-installer"
TAR="${PKG}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${TAG}/${TAR}"
WORKDIR="${TMPDIR:-/tmp}/foliodrive-bootstrap-$$"

log() { printf '\n==> %s\n' "$*"; }

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Não rode este script como root. Use um usuário normal (o instalador pedirá sudo)."
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
  if [[ "${ID:-}" != "ubuntu" ]] || [[ "${VERSION_ID:-}" != "24.04" ]]; then
    echo "AVISO: o pacote FolioDrive ${VERSION} foi testado em Ubuntu 24.04 GNOME."
    echo "       Seu sistema: ${PRETTY_NAME:-desconhecido} (VERSION_ID=${VERSION_ID:-?})"
    echo "       Pode funcionar, mas ainda não foi validado nesta versão."
  fi
fi

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta o comando: $1"
    echo "Instale com: sudo apt-get install -y $1"
    exit 1
  }
}

need tar
if command -v curl >/dev/null 2>&1; then
  DOWNLOAD=(curl -fL --progress-bar -o)
elif command -v wget >/dev/null 2>&1; then
  DOWNLOAD=(wget -O)
else
  echo "Instale curl ou wget: sudo apt-get install -y curl"
  exit 1
fi

mkdir -p "${WORKDIR}"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT

log "Baixando FolioDrive ${VERSION} (Release ${TAG} do GitHub FolioDrive)…"
echo "URL: ${URL}"
"${DOWNLOAD[@]}" "${WORKDIR}/${TAR}" "${URL}"

log "Extraindo…"
tar -xzf "${WORKDIR}/${TAR}" -C "${WORKDIR}"

INSTALL_ROOT="${WORKDIR}/${PKG}"
if [[ ! -f "${INSTALL_ROOT}/installer/install-foliodrive.sh" ]]; then
  found="$(find "${WORKDIR}" -maxdepth 3 -type f -name install-foliodrive.sh 2>/dev/null | head -1 || true)"
  if [[ -n "${found}" ]]; then
    INSTALL_ROOT="$(cd "$(dirname "${found}")/.." && pwd)"
  fi
fi

if [[ ! -f "${INSTALL_ROOT}/installer/install-foliodrive.sh" ]]; then
  echo "Pacote inválido: install-foliodrive.sh não encontrado."
  exit 1
fi

chmod +x "${INSTALL_ROOT}/installer/install-foliodrive.sh"
chmod +x "${INSTALL_ROOT}/installer/steps/"*.sh 2>/dev/null || true

log "Instalando…"
bash "${INSTALL_ROOT}/installer/install-foliodrive.sh" "$@"

log "Concluído."
echo "Abra SeaDrive (login no seu servidor) e depois FolioDrive em ~/SeaDrive."
