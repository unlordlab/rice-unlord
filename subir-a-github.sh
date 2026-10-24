#!/usr/bin/env bash
# Sube (o actualiza) este paquete a un repositorio PRIVADO de GitHub: rice-unlord
# Primera vez: lo crea y lo sube.  Siguientes veces: sube solo los cambios.
# Recuperar en otro PC:  gh repo clone rice-unlord && cd rice-unlord && bash instalar.sh
set -e
cd "$(dirname "$0")"
REPO="${REPO:-rice-unlord}"
command -v git >/dev/null || { echo "Falta git: sudo pacman -S git"; exit 1; }
command -v gh  >/dev/null || { echo "Falta GitHub CLI: sudo pacman -S github-cli"; exit 1; }
gh auth status >/dev/null 2>&1 || gh auth login --web --git-protocol https
[ -d .git ] || git init -q -b main
git config user.name  >/dev/null || git config user.name  "$(gh api user -q .login)"
git config user.email >/dev/null || git config user.email "$(gh api user -q .login)@users.noreply.github.com"
# Seguridad: parar si aparece algo que parezca un secreto
if git ls-files --others --cached --exclude-standard | grep -Ei '(^|/)\.env|id_(rsa|ed25519)|\.pem$|\.key$'; then
  echo "He encontrado archivos que parecen secretos (arriba). No subo nada."; exit 1; fi
git add -A
git diff --cached --quiet && echo "Sin cambios que subir." || git commit -qm "Rice Unlord · $(date '+%Y-%m-%d %H:%M')"
if git remote get-url origin >/dev/null 2>&1; then git push -q origin main
elif gh repo view "$REPO" >/dev/null 2>&1; then
  git remote add origin "https://github.com/$(gh api user -q .login)/$REPO.git"; git push -q -u origin main
else gh repo create "$REPO" --private --source=. --remote=origin --push >/dev/null; fi
echo "Hecho: https://github.com/$(gh api user -q .login)/$REPO (privado)"
