#!/usr/bin/env bash
# Patches de branding + app-id distinto (evita single-instance do Arquivos do SO).
set -euo pipefail

SRC="${1:?usage: apply-branding.sh /path/to/nautilus-src}"

if [[ ! -f "${SRC}/meson.build" ]]; then
  echo "Não parece source Nautilus: ${SRC}"
  exit 1
fi

# Application ID / D-Bus — obrigatório para 2º gerenciador real
find "${SRC}" -type f \( \
  -name '*.c' -o -name '*.h' -o -name '*.ui' -o -name '*.xml' \
  -o -name '*.in' -o -name '*.in.in' -o -name 'meson.build' \
  -o -name '*.desktop*' -o -name '*.service*' -o -name '*.gschema*' \
\) -print0 2>/dev/null \
  | xargs -0 sed -i \
    -e 's/org\.gnome\.Nautilus/com.foliodrive.Files/g' \
    -e 's/org\.gnome\.nautilus/com.foliodrive.files/g' \
  2>/dev/null || true

# Nome visível
find "${SRC}" -type f \( -name '*.ui' -o -name '*.c' -o -name '*.po' -o -name '*.desktop*' \) -print0 2>/dev/null \
  | xargs -0 sed -i \
    -e 's/>\s*Files\s*</>FolioDrive</g' \
    -e 's/Name=Files/Name=FolioDrive/g' \
    -e 's/"Files"/"FolioDrive"/g' \
  2>/dev/null || true

# Desktop template clássico
for f in \
  "${SRC}/data/org.gnome.Nautilus.desktop.in.in" \
  "${SRC}/data/org.gnome.Nautilus.desktop.in" \
  "${SRC}/data/com.foliodrive.Files.desktop.in.in" \
  "${SRC}/data/com.foliodrive.Files.desktop.in"
do
  if [[ -f "${f}" ]]; then
    sed -i 's/Name=Files/Name=FolioDrive/g' "${f}" || true
  fi
done

echo "Branding FolioDrive + app-id com.foliodrive.Files aplicado em ${SRC}"
