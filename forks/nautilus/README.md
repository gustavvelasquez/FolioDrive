# Nautilus fork (FolioDrive)

Build no **Ubuntu 26.04** (maintainer):

```bash
cd FolioDrive   # ou product/
chmod +x scripts/build-foliodrive-files.sh forks/nautilus/apply-branding.sh
./scripts/build-foliodrive-files.sh
```

Produz `bundle/foliodrive-files-50.2.2-foliodrive.1.tar.gz` → `/opt/foliodrive/bin/foliodrive-files` (**ELF**, app-id `com.foliodrive.Files`).

Upstream pinado: **GNOME Nautilus 50.2.2** (Ubuntu 26.04). O **Arquivos** do SO permanece; FolioDrive é o 2º gerenciador.

Licença upstream: **GPL-3.0-or-later**.

**Não** use `build-foliodrive-files-wrapper.sh` no Release (só debug).
