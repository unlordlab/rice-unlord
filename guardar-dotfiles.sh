#!/usr/bin/env bash
# Guarda tus ajustes personales (los que cambies a mano tras instalar el rice)
# en un repositorio PRIVADO de GitHub llamado "dotfiles", usando chezmoi.
# Ejecútalo cada vez que retoques algo que quieras conservar.
# Recuperar en un PC nuevo:  chezmoi init --apply https://github.com/TU_USUARIO/dotfiles.git
set -e
command -v chezmoi >/dev/null || { echo "Falta chezmoi: sudo pacman -S chezmoi"; exit 1; }
command -v gh >/dev/null || { echo "Falta GitHub CLI: sudo pacman -S github-cli"; exit 1; }
gh auth status >/dev/null 2>&1 || gh auth login --web --git-protocol https
[ -d "$(chezmoi source-path 2>/dev/null)" ] || chezmoi init

# Qué se guarda (añade o quita líneas a tu gusto). Nada de contraseñas ni claves.
LISTA=(
  ~/.config/fish/config.fish
  ~/.config/starship.toml
  ~/.config/fastfetch
  ~/.config/kdeglobals
  ~/.config/kwinrc
  ~/.config/kglobalshortcutsrc
  ~/.config/kxkbrc
  ~/.config/kcminputrc
  ~/.config/kscreenlockerrc
  ~/.config/konsolerc
  ~/.config/plasma-org.kde.plasma.desktop-appletsrc
  ~/.config/plasmashellrc
  ~/.local/share/konsole
  ~/.config/rsu-widget
  ~/.config/btop/btop.conf
  ~/.config/easyeffects/db/easyeffectsrc
  ~/.local/share/easyeffects/output
  ~/.local/share/easyeffects/autoload
  ~/.config/spicetify/config-xpui.ini
  ~/.config/koirc
  ~/.config/klassy
  ~/.config/Code/User/settings.json
  ~/.config/autostart
  ~/.config/rsu-assistent
  ~/.local/share/applications/elia-veu.desktop
  ~/.local/share/applications/com.anthropic.Claude.desktop
)
for f in "${LISTA[@]}"; do [ -e "$f" ] && chezmoi add "$f" && echo "  + ${f/#$HOME/~}"; done

cd "$(chezmoi source-path)"
if grep -rIlE '(api[_-]?key|secret|token|password)\s*[=:]' . --exclude-dir=.git | grep -v '^$'; then
  echo "Ojo: esos archivos contienen algo que parece una clave. Revísalos antes de subir. No subo nada."; exit 1; fi
git add -A
git diff --cached --quiet && { echo "Sin cambios."; exit 0; }
git commit -qm "Ajustes · $(date '+%Y-%m-%d %H:%M')"
if git remote get-url origin >/dev/null 2>&1; then git push -q origin HEAD
elif gh repo view dotfiles >/dev/null 2>&1; then git remote add origin "https://github.com/$(gh api user -q .login)/dotfiles.git"; git push -q -u origin HEAD
else gh repo create dotfiles --private --source=. --remote=origin --push >/dev/null; fi
echo "Hecho: https://github.com/$(gh api user -q .login)/dotfiles (privado)"
