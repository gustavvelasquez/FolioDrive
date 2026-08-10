# Build FolioDrive na VM Ubuntu 24.04

O bundle **não** vai no git. Monte-o na VM (ou Windows parcial + VM para teste).

## Opção A — VM Ubuntu (recomendado, teste real)

```bash
git clone https://github.com/gustavvelasquez/FolioDrive.git
cd FolioDrive
chmod +x scripts/*.sh installer/install-foliodrive.sh installer/steps/*.sh
./scripts/build-all.sh
./installer/install-foliodrive.sh --start
```

`build-all.sh` = fetch SeaDrive + build foliodrive-files (meson ou apt fallback) + bundle + sha256 + package.

## Opção B — Windows (bundle parcial, teste na VM)

```powershell
cd c:\Repositorios\StorageOneDriveLike\product
.\scripts\fetch-seadrive.ps1
.\scripts\build-foliodrive-files-wrapper.ps1
```

Copie a pasta `product/` para a VM (`copy-lab-client-to-ubuntu.ps1` adaptado) e na VM:

```bash
cd ~/FolioDrive   # ou product
./scripts/build-bundle.sh
./scripts/update-versions.sh
./scripts/package-release.sh
./installer/install-foliodrive.sh
```

## Release GitHub

Anexe `dist/FolioDrive-0.1.0-installer.tar.gz` na tag `v0.1.0`.

## Wrapper vs build completo

- **wrapper** (`build-foliodrive-files-wrapper.*`): `foliodrive-files` delega a `/usr/bin/nautilus`; apt instala nautilus no runtime. OK para v0.1.0.
- **apt/meson**: Nautilus pinado em `/opt/foliodrive` (promover depois no lab).
