#!/usr/bin/env bash
# Patches de branding + app-id distinto (evita single-instance do Arquivos do SO).
set -euo pipefail

SRC="${1:?usage: apply-branding.sh /path/to-nautilus-src}"

if [[ ! -f "${SRC}/meson.build" ]]; then
  echo "Não parece source Nautilus: ${SRC}"
  exit 1
fi

# Application ID / D-Bus — obrigatório para 2º gerenciador real
find "${SRC}" -type f \( \
  -name '*.c' -o -name '*.h' -o -name '*.ui' -o -name '*.xml' \
  -o -name '*.in' -o -name '*.in.in' -o -name 'meson.build' \
  -o -name '*.desktop*' -o -name '*.service*' -o -name '*.gschema*' \
  -o -name '*.blp' -o -name '*.ini' -o -name '*.ini.in' \
\) -print0 2>/dev/null \
  | xargs -0 sed -i \
    -e 's/org\.gnome\.Nautilus/com.foliodrive.Files/g' \
    -e 's/org\.gnome\.nautilus/com.foliodrive.files/g' \
  2>/dev/null || true

# Nome visível
find "${SRC}" -type f \( -name '*.ui' -o -name '*.c' -o -name '*.po' -o -name '*.desktop*' -o -name '*.blp' \) -print0 2>/dev/null \
  | xargs -0 sed -i \
    -e 's/>\s*Files\s*</>FolioDrive</g' \
    -e 's/Name=Files/Name=FolioDrive/g' \
  2>/dev/null || true

rename_if_exists() {
  local from="$1" to="$2"
  if [[ -f "${from}" && ! -e "${to}" ]]; then
    cp -a "${from}" "${to}"
  fi
}

# Copiar TODOS os arquivos cujo nome ainda é org.gnome.Nautilus* / org.gnome.nautilus*
while IFS= read -r -d '' f; do
  dir="$(dirname "${f}")"
  base="$(basename "${f}")"
  newbase="${base//org.gnome.Nautilus/com.foliodrive.Files}"
  newbase="${newbase//org.gnome.nautilus/com.foliodrive.files}"
  if [[ "${base}" != "${newbase}" ]]; then
    rename_if_exists "${f}" "${dir}/${newbase}"
  fi
done < <(find "${SRC}" -type f \( -name '*org.gnome.Nautilus*' -o -name '*org.gnome.nautilus*' \) -print0 2>/dev/null)

# Conferências mínimas
test -f "${SRC}/data/icons/hicolor/scalable/apps/com.foliodrive.Files.svg"
test -f "${SRC}/data/com.foliodrive.files.gschema.xml"

echo "Branding FolioDrive + app-id com.foliodrive.Files aplicado em ${SRC}"
