# Flatpak / Flathub (fase 2)

O instalador **`.sh`** é o canal do 1º release. Flatpak entra depois para
update automático estilo loja, com a **mesma** stack pinada em `VERSIONS.json`.

## Próximos passos (não implementado)

1. Manifest `com.foliodrive.Client.yml` empacotando:
   - SeaDrive AppImage pinado (runtime extension ou wrapper)
   - `foliodrive-files` prefix
   - Extensão no prefix FolioDrive
2. Publicar em Flathub após `.sh` estável no lab.
3. Usuário: `flatpak update` recebe versões **promovidas** pelo maintainer.

## Referência

- https://docs.flathub.org/docs/for-app-authors/submission
- Mesma política: nenhum download upstream no runtime do usuário; blobs
  vendored no build Flathub a partir dos releases FolioDrive.
