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
  -o -name '*.blp' \
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

# Renomear assets cujo path o meson espera com o app-id novo
rename_if_exists() {
  local from="$1" to="$2"
  if [[ -f "${from}" && ! -f "${to}" ]]; then
    cp -a "${from}" "${to}"
  fi
}

ICON_SCALABLE="${SRC}/data/icons/hicolor/scalable/apps"
ICON_SYMBOLIC="${SRC}/data/icons/hicolor/symbolic/apps"
rename_if_exists "${ICON_SCALABLE}/org.gnome.Nautilus.svg" "${ICON_SCALABLE}/com.foliodrive.Files.svg"
rename_if_exists "${ICON_SCALABLE}/org.gnome.NautilusDevel.svg" "${ICON_SCALABLE}/com.foliodrive.FilesDevel.svg"
rename_if_exists "${ICON_SYMBOLIC}/org.gnome.Nautilus-symbolic.svg" "${ICON_SYMBOLIC}/com.foliodrive.Files-symbolic.svg"

# Desktop / service templates no data/
DATA="${SRC}/data"
for pair in \
  "org.gnome.Nautilus.desktop.in.in:com.foliodrive.Files.desktop.in.in" \
  "org.gnome.Nautilus.desktop.in:com.foliodrive.Files.desktop.in"
do
  from="${DATA}/${pair%%:*}"
  to="${DATA}/${pair##*:}"
  rename_if_exists "${from}" "${to}"
done

# Qualquer outro arquivo data/ ainda com nome antigo referenciado
while IFS= read -r -d '' f; do
  base="$(basename "${f}")"
  newbase="${base//org.gnome.Nautilus/com.foliodrive.Files}"
  if [[ "${base}" != "${newbase}" ]]; then
    dest="$(dirname "${f}")/${newbase}"
    rename_if_exists "${f}" "${dest}"
  fi
done < <(find "${DATA}" -type f -name '*org.gnome.Nautilus*' -print0 2>/dev/null)

echo "Branding FolioDrive + app-id com.foliodrive.Files aplicado em ${SRC}"
