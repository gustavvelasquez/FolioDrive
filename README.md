# FolioDrive

Client Linux open source estilo OneDrive para **Seafile** (self-hosted): pasta `~/SeaDrive`, **Free up space**, **Always keep**, coluna de status no gerenciador **FolioDrive** (fork Nautilus pinado).

| Item | Valor |
|------|--------|
| Alvo | Ubuntu 24.04 LTS Desktop GNOME (x86_64) |
| Stack | SeaDrive AppImage + `foliodrive-files` + extensão (pinados) |
| Servidor | Seafile do usuário (Docker) — **não** incluído |

Desenvolvimento nesta pasta (`product/` no lab); promovido para o repo **FolioDrive** (produção).

## Instalação (usuário)

Baixe `FolioDrive-x.y.z-installer.tar.gz` em **Releases** do repo FolioDrive:

```bash
tar -xzf FolioDrive-0.1.0-installer.tar.gz
cd FolioDrive-0.1.0-installer
chmod +x installer/install-foliodrive.sh installer/steps/*.sh
./installer/install-foliodrive.sh
```

1. Abra **SeaDrive** → login no seu servidor Seafile  
2. Abra **FolioDrive** em `~/SeaDrive`

O instalador **não** baixa nada de seafile.com ou GNOME upstream.

## Maintainer (lab Ubuntu 24.04)

```bash
cd product
chmod +x scripts/*.sh forks/nautilus/apply-branding.sh installer/install-foliodrive.sh installer/steps/*.sh
./scripts/fetch-seadrive.sh              # uma vez: pin SeaDrive (maintainer)
./scripts/build-foliodrive-files.sh      # build Nautilus fork → tarball
./scripts/build-bundle.sh
./scripts/update-versions.sh
./installer/install-foliodrive.sh        # teste na VM
./scripts/package-release.sh             # artefato para GitHub Release
```

Promover para produção:

```powershell
# Windows (host)
.\product\scripts\promote-to-foliodrive.ps1
```

```bash
# Linux / Git Bash
./product/scripts/promote-to-foliodrive.sh
```

Publicar GitHub: após promover, ver `SETUP-GITHUB.md` no repo FolioDrive.

## Estrutura

```
product/
  VERSIONS.json          # pins canônicos
  bundle/                # blobs (Release, não git)
  installer/             # install-foliodrive.sh + steps/
  scripts/               # build, fetch, promote, package-release
  forks/nautilus/        # branding + build doc
  assets/                # .desktop
  flatpak/               # fase 2 (Flathub)
  extension/             # aponta para forks/seadrive-ext
```

## Licença

GPL-3.0 — [LICENSE](LICENSE) · [NOTICE](NOTICE)
