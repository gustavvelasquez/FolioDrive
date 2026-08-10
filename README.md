# FolioDrive

Client Linux **open source** com experiência estilo OneDrive, usando nuvem **Seafile** (servidor seu).

Pasta `~/SeaDrive` sob demanda, menus **Free up space** / **Always keep** e coluna de status.

| Item | Valor |
|------|--------|
| Sistema | Ubuntu 24.04 LTS Desktop GNOME (x86_64) |
| Servidor Seafile | Instalação à parte (Docker) — **não** vem neste pacote |

---

## Como instalar (Ubuntu novo)

**Não precisa clonar este repositório.** Baixe o pacote na página de [Releases](https://github.com/gustavvelasquez/FolioDrive/releases) e instale:

```bash
wget https://github.com/gustavvelasquez/FolioDrive/releases/download/v0.1.0/FolioDrive-0.1.0-installer.tar.gz
tar -xzf FolioDrive-0.1.0-installer.tar.gz
cd FolioDrive-0.1.0-installer
chmod +x installer/install-foliodrive.sh installer/steps/*.sh
./installer/install-foliodrive.sh
```

Depois:

1. Abra **SeaDrive** e faça login no **seu** servidor Seafile  
2. Abra **FolioDrive** em `~/SeaDrive`  
3. Teste Free up space / Always keep e a coluna SeaDrive  

O instalador **não** baixa nada do site oficial do Seafile: tudo já vem pinado dentro do `.tar.gz` do Release.

---

## O que é este repositório (git)

- Código do instalador, extensão, `VERSIONS.json`, docs  
- Para **desenvolvimento** e manutenção  
- Arquivos grandes (AppImage SeaDrive, etc.) ficam no **Release**, não no clone  

Clonar o git **sem** o pacote do Release **não** basta para instalar.

---

## Desenvolvimento / montar um release novo

Feito no lab ou nesta pasta, **só pelo maintainer** (não é passo do usuário final):

```bash
./scripts/fetch-seadrive.sh
./scripts/build-foliodrive-files-wrapper.sh   # ou build-foliodrive-files.sh
./scripts/build-bundle.sh
./scripts/update-versions.sh
./scripts/package-release.sh
```

Anexe `dist/FolioDrive-x.y.z-installer.tar.gz` à Release no GitHub.

Detalhes: [docs/VM-BUILD.md](docs/VM-BUILD.md)

## Licença

GPL-3.0 — [LICENSE](LICENSE) · [NOTICE](NOTICE)

Mensagens de commit deste projeto: **português do Brasil**.
