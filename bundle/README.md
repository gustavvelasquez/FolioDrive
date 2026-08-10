# Bundle FolioDrive (blobs pinados)

Esta pasta recebe os artefatos **congelados** antes de montar o release.

## Maintainer (lab Ubuntu 24.04)

```bash
cd ~/StorageOneDriveLike/product
./scripts/fetch-seadrive.sh          # baixa AppImage 3.0.23 uma vez
./scripts/build-foliodrive-files.sh  # build Nautilus fork → tarball
./scripts/build-bundle.sh            # copia extensão + ícones + VERSIONS
./scripts/update-versions.sh         # preenche sha256 em bundle/VERSIONS.json
```

O instalador **não** baixa nada da internet. Todos os arquivos listados em `VERSIONS.json` devem estar aqui.
