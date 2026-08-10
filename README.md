# FolioDrive

Client Linux **open source** com experiência estilo OneDrive, usando nuvem **Seafile** (servidor seu).

Pasta `~/SeaDrive` sob demanda, menus **Free up space** / **Always keep** e coluna de status.

| Item | Valor |
|------|--------|
| Sistema | Ubuntu **26.04** LTS Desktop GNOME (x86_64) |
| Servidor Seafile | Instalação à parte (Docker) — **não** vem neste pacote |

---

## Como instalar (Ubuntu novo)

**Um comando** (baixa o pacote da [Release](https://github.com/gustavvelasquez/FolioDrive/releases) deste repositório e instala):

```bash
curl -fsSL https://raw.githubusercontent.com/gustavvelasquez/FolioDrive/main/install.sh | bash
```

Sem pipe (se preferir ver o script antes):

```bash
wget -qO install.sh https://raw.githubusercontent.com/gustavvelasquez/FolioDrive/main/install.sh
bash install.sh
```

Depois:

1. Abra **SeaDrive** e faça login no **seu** servidor Seafile  
2. Abra **FolioDrive** em `~/SeaDrive`  
3. Teste Free up space / Always keep e a coluna SeaDrive  

O `install.sh` **não** baixa do site do Seafile: só puxa o `.tar.gz` pinado da **Release FolioDrive** (v0.1.0).

**LibreOffice Calc:** o instalador pode instalar o Calc só para **teste** de abrir `.xlsx`. **Não** faz parte do produto final e **será removido** numa versão futura. Para pular: `bash install.sh --skip-libreoffice`.

### Onde fica o quê no GitHub

| Onde | O que é | Exemplo |
|------|---------|---------|
| Aba **Code** (`main`) | Código pequeno (scripts, README) | `install.sh`, `installer/` |
| Aba **Releases** | Pacote instalável (~154 MB) | `FolioDrive-0.1.0-installer.tar.gz` (dentro: AppImage SeaDrive, extensão…) |

Página Releases: https://github.com/gustavvelasquez/FolioDrive/releases

---

## Desenvolvimento (só maintainer)

Não é passo do usuário. Montar um release novo (no Ubuntu ou no lab):

```bash
./scripts/fetch-seadrive.sh
./scripts/build-foliodrive-files-wrapper.sh
./scripts/build-bundle.sh
./scripts/update-versions.sh
./scripts/package-release.sh
```

Anexe o `.tar.gz` em uma Release nova e atualize a versão em `install.sh` / `VERSIONS.json`.

Detalhes: [docs/VM-BUILD.md](docs/VM-BUILD.md)

## Licença

GPL-3.0 — [LICENSE](LICENSE) · [NOTICE](NOTICE)

Commits: **português do Brasil** ([CONTRIBUTING.md](CONTRIBUTING.md)).
