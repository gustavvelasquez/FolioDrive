# FolioDrive — publicar no GitHub

O `gh` CLI não está instalado neste PC. Crie o repositório manualmente:

1. https://github.com/new → nome **FolioDrive** → **Public**
2. No PowerShell:

```powershell
cd C:\Repositorios\FolioDrive
git add -A
git commit -m "Initial FolioDrive product scaffold"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/FolioDrive.git
git push -u origin main
```

Substitua `SEU_USUARIO` pelo seu login GitHub (conta pessoal).

## Releases

Após montar `bundle/` na VM Ubuntu:

```bash
./scripts/package-release.sh
```

Anexe `dist/FolioDrive-0.1.0-installer.tar.gz` ao GitHub Release tag `v0.1.0`.
