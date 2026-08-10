# Build FolioDrive na VM Ubuntu 26.04

O bundle **não** vai no git. Artefato final fica na **GitHub Release**.  
Pode **apagar a VM** depois do upload; para rebuild futuro use outra Ubuntu 26.04 GNOME + esta receita.

## 1) Clone

```bash
git clone https://github.com/gustavvelasquez/FolioDrive.git
cd FolioDrive
chmod +x scripts/*.sh forks/nautilus/apply-branding.sh \
  installer/install-foliodrive.sh installer/steps/*.sh
```

## 2) Dependências apt (build do fork Nautilus 50.2.2)

O script `build-foliodrive-files.sh` instala isso sozinho; lista explícita para referência:

```bash
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential meson ninja-build pkg-config git wget \
  libglib2.0-dev libgtk-4-dev libadwaita-1-dev \
  libportal-dev libportal-gtk4-dev \
  libgexiv2-dev libcloudproviders-dev libcue-dev \
  libxml2-dev libsqlite3-dev \
  python3-nautilus libnautilus-extension-dev \
  gettext desktop-file-utils shared-mime-info \
  libglycin-2-dev libglycin-gtk4-2-dev \
  libgnome-autoar-0-dev libgnome-autoar-gtk-0-dev \
  libgnome-desktop-4-dev libicu-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libtinysparql-dev libgdk-pixbuf-2.0-dev \
  blueprint-compiler \
  gobject-introspection libgirepository1.0-dev libgirepository-2.0-dev
```

## 3) Source Nautilus 50.2.2

Upstream pinado: **GNOME Nautilus 50.2.2** (Ubuntu 26.04).

O build tenta baixar de `download.gnome.org`. Se a VM não alcançar (arquivo 0 bytes / timeout):

1. No Windows (ou outro host): baixe  
   https://download.gnome.org/sources/nautilus/50/nautilus-50.2.2.tar.xz  
2. Copie para a VM: `/tmp/nautilus-50.2.2.tar.xz`  
3. O script usa wget; se preferir, deixe o tarball em `/tmp` e adapte, ou rode o build após colocar o arquivo onde o script espera.

Flags importantes do meson (já no script):

- `-Dtests=none`
- `-Dextensions=false` — Ubuntu 26.04 tem `gexiv2` antigo; extensões stock do Nautilus quebram o compile
- Branding: `forks/nautilus/apply-branding.sh` → app-id `com.foliodrive.Files`
- Patch `gexiv2-0.16` → `gexiv2` no `meson.build`

VM com pouca RAM:

```bash
NINJA_JOBS=1 ./scripts/build-foliodrive-files.sh
```

Saída: `bundle/foliodrive-files-50.2.2-foliodrive.1.tar.gz` (**ELF**, não wrapper bash).

Conferir:

```bash
tar -tzf bundle/foliodrive-files-50.2.2-foliodrive.1.tar.gz | head
# após install local:
file /opt/foliodrive/bin/foliodrive-files   # deve ser ELF 64-bit
```

## 4) Bundle + package

```bash
# SeaDrive pinado (ou copie de ~/Applications se já tiver)
./scripts/fetch-seadrive.sh
# ou: cp ~/Applications/SeaDrive-x86_64-3.0.23.AppImage bundle/

./scripts/build-bundle.sh
./scripts/update-versions.sh
./scripts/package-release.sh
```

Pipeline único: `./scripts/build-all.sh` (fetch + fork + bundle + versions + package).

Artefato: `dist/FolioDrive-0.1.0-installer.tar.gz`

## 5) Teste rápido na VM

```bash
./installer/install-foliodrive.sh
file /opt/foliodrive/bin/foliodrive-files
# GUI: Arquivos (SO) sem menus SeaDrive; FolioDrive com Free up / Always keep + coluna
```

Isolamento produto:

- Extensão só em `/opt/foliodrive/share/nautilus-python/extensions/`
- UI (lista/coluna) em schemas `com.foliodrive.files.*` — **não** `org.gnome.nautilus.*`

## 6) Release GitHub

Anexe/substitua `dist/FolioDrive-0.1.0-installer.tar.gz` na tag `v0.1.0`.

Instalação do usuário:

```bash
curl -fsSL https://raw.githubusercontent.com/gustavvelasquez/FolioDrive/main/install.sh | bash
```

## Wrapper vs fork

- **fork (produto):** `build-foliodrive-files.sh` → ELF em `/opt/foliodrive`, app-id FolioDrive.
- **wrapper (debug only):** `build-foliodrive-files-wrapper.sh` — **proibido** no Release.

## Pode apagar a VM?

**Sim**, depois do asset na Release e do código no `main`. Rebuild = nova Ubuntu 26.04 + esta página.
