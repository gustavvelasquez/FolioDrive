#!/usr/bin/env bash
# Patches mínimos de branding no source Nautilus (FolioDrive).
set -euo pipefail

SRC="${1:?usage: apply-branding.sh /path/to/nautilus-src}"

if [[ ! -f "${SRC}/meson.build" ]]; then
  echo "Não parece source Nautilus: ${SRC}"
  exit 1
fi

# Nome visível em about/dialogs onde houver string óbvia
find "${SRC}" -type f \( -name '*.ui' -o -name '*.c' -o -name '*.po' \) -print0 2>/dev/null \
  | xargs -0 sed -i 's/>\s*Files\s*</>FolioDrive</g' 2>/dev/null || true

# Desktop template se existir
if [[ -f "${SRC}/data/org.gnome.Nautilus.desktop.in.in" ]]; then
  sed -i 's/org\.gnome\.Nautilus/com.foliodrive.Files/g' \
    "${SRC}/data/org.gnome.Nautilus.desktop.in.in" || true
  sed -i 's/Name=Files/Name=FolioDrive/g' \
    "${SRC}/data/org.gnome.Nautilus.desktop.in.in" || true
fi

echo "Branding FolioDrive aplicado em ${SRC}"
