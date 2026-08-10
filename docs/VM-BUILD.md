# Build FolioDrive na VM Ubuntu 26.04

O bundle **não** vai no git. Monte-o numa máquina **Linux Ubuntu 26.04** (VM lab, outra host ou CI).

## Pipeline completo (recomendado)

```bash
git clone https://github.com/gustavvelasquez/FolioDrive.git
cd FolioDrive
chmod +x scripts/*.sh installer/install-foliodrive.sh installer/steps/*.sh
./scripts/build-all.sh
./installer/install-foliodrive.sh --start
```

`build-all.sh` = fetch SeaDrive + **build meson do fork** Nautilus + bundle + sha256 + package.

VM com pouca RAM: `NINJA_JOBS=1 ./scripts/build-foliodrive-files.sh`

## Release GitHub

Anexe `dist/FolioDrive-0.1.0-installer.tar.gz` na tag `v0.1.0`.

## Wrapper vs fork

- **fork (produto):** `build-foliodrive-files.sh` → ELF em `/opt/foliodrive`, app-id FolioDrive.
- **wrapper (debug only):** `build-foliodrive-files-wrapper.sh` — **proibido** no Release.
