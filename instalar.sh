#!/usr/bin/env bash
# ============================================================
#  RICE UNLORD / RSU — instalador único (KDE Plasma 6, CachyOS)
#  Uso:   bash instalar.sh            → menú
#         bash instalar.sh todo       → todo lo que no necesita sudo
#         bash instalar.sh 1 3 8      → solo esos módulos
#  No usa sudo. Lo de sistema (GRUB, SDDM, Plymouth) va aparte:
#         bash instalar-sistema.sh
# ============================================================
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; M="$D/modulos"
FONS="$HOME/Imatges/fons-unlord"
q() { command -v "$1" >/dev/null 2>&1; }
ok()   { printf '   \e[32m✔\e[0m %s\n' "$*"; }
warn() { printf '   \e[33m!\e[0m %s\n' "$*"; }
tit()  { printf '\n\e[1;31m▌\e[0m\e[1m %s\e[0m\n' "$*"; }
QDBUS=$(q qdbus6 && echo qdbus6 || echo qdbus)
TEMA="${TEMA:-}"

NOMS=( ""
 "Fondos de pantalla"
 "Colores KDE (claro Unlord / oscuro Nit)"
 "Iconos Unlord"
 "Cursor Unlord"
 "Sonidos del sistema"
 "Fuentes (Share Tech Mono, Barlow Condensed)"
 "Terminal: Konsole, fastfetch y starship"
 "Widget RSU · Vigilància"
 "Pantalla de bloqueo"
 "Paneles y dock (borra los paneles actuales)"
 "Iconos de proyectos en el escritorio"
 "Pieles de apps: VS Code y btop"
 "Spotify (necesita spicetify)"
 "Fondo vivo con el mercado (S&P 500 + VIX, cada 15 min)"
 "Asistente de voz Elia (Newelle + Ollama)" )
N=$(( ${#NOMS[@]} - 1 ))

backup() {
  BK="$HOME/.config/unlord-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BK"
  for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kdeglobals kwinrc konsolerc kcminputrc kscreenlockerrc; do
    [ -f "$HOME/.config/$f" ] && cp "$HOME/.config/$f" "$BK/"; done
  ok "Copia de seguridad de tu configuración en $BK"
}

m1() { mkdir -p "$FONS"; cp "$M"/fondos/*.png "$FONS/"; ok "$(ls "$M"/fondos | wc -l) fondos en $FONS"; }
m2() {
  mkdir -p "$HOME/.local/share/color-schemes"; cp "$M"/kde/*.colors "$HOME/.local/share/color-schemes/"
  local s=Unlord; [ "$TEMA" = nit ] && s=UnlordNit
  if q plasma-apply-colorscheme; then plasma-apply-colorscheme "$s" >/dev/null && ok "Colores: $s"; else warn "Elige $s en Configuración → Colores"; fi
}
m3() {
  mkdir -p "$HOME/.local/share/icons"; cp -r "$M/iconos/Unlord" "$HOME/.local/share/icons/"
  if [ -x /usr/lib/plasma-changeicons ]; then /usr/lib/plasma-changeicons Unlord >/dev/null 2>&1
  else kwriteconfig6 --file kdeglobals --group Icons --key Theme Unlord; fi; ok "Iconos Unlord"
}
m4() {
  mkdir -p "$HOME/.local/share/icons" "$HOME/.icons"; cp -a "$M/cursor/Unlord-cursor" "$HOME/.local/share/icons/"
  cp -a "$M/cursor/Unlord-cursor" "$HOME/.icons/"   # KDE solo lo ve aquí en CachyOS
  if q plasma-apply-cursortheme; then plasma-apply-cursortheme Unlord-cursor >/dev/null 2>&1 && ok "Cursor Unlord"
  else kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Unlord-cursor; ok "Cursor Unlord (se ve al volver a entrar)"; fi
}
m5() {
  mkdir -p "$HOME/.local/share/sounds"; cp -r "$M/sonidos/Unlord" "$HOME/.local/share/sounds/"
  kwriteconfig6 --file kdeglobals --group Sounds --key Theme Unlord; ok "Sonidos Unlord (si no suenan: Configuración → Sonidos del sistema → Unlord)"
}
m6() { mkdir -p "$HOME/.local/share/fonts"; cp "$M"/fuentes/*.ttf "$HOME/.local/share/fonts/"; fc-cache -f >/dev/null 2>&1; ok "Fuentes instaladas"; }
m7() {
  mkdir -p "$HOME/.local/share/konsole" "$HOME/.config/fastfetch"
  cp "$M"/kde/*.colorscheme "$M/kde/Unlord.profile" "$HOME/.local/share/konsole/"
  [ "$TEMA" = nit ] && sed -i 's/^ColorScheme=Unlord$/ColorScheme=UnlordNit/' "$HOME/.local/share/konsole/Unlord.profile"
  kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Unlord.profile
  kwriteconfig6 --file konsolerc --group MainWindow --key MenuBar Disabled
  cp "$M"/terminal/config.jsonc "$M"/terminal/logo-*.txt "$HOME/.config/fastfetch/"
  cp "$M/terminal/starship.toml" "$HOME/.config/starship.toml"
  local F="$HOME/.config/fish/config.fish"; mkdir -p "$(dirname "$F")"; touch "$F"
  grep -q "starship init fish" "$F" || printf '\nif status is-interactive\n    fastfetch\n    starship init fish | source\nend\n' >> "$F"
  ok "Konsole, fastfetch y starship"; q starship || warn "Falta starship: bash paquetes.sh"; q fastfetch || warn "Falta fastfetch: bash paquetes.sh"
}
m8() {
  mkdir -p "$HOME/.local/bin"; install -m 755 "$M/widget/bin/rsu-widget-dades" "$HOME/.local/bin/"
  if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q org.unlord.rsu; then kpackagetool6 -t Plasma/Applet -u "$M/widget/org.unlord.rsu" >/dev/null
  else kpackagetool6 -t Plasma/Applet -i "$M/widget/org.unlord.rsu" >/dev/null; fi
  "$HOME/.local/bin/rsu-widget-dades" >/dev/null 2>&1 || true
  ok "Widget RSU instalado · tus valores en ~/.config/rsu-widget/config.json"
}
m9() {
  local img="$FONS/unlord-rsu-bloqueig-2560x1440.png"; [ "$TEMA" = nit ] && img="$FONS/unlord-rsu-bloqueig-nit-2560x1440.png"
  [ -f "$img" ] || m1 >/dev/null
  kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$img"
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$img"
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key showMediaControls --type bool false
  ok "Pantalla de bloqueo (pruébala con Meta+L)"
}
m10() {
  local JS; JS="$(sed "s#__HOME__#$HOME#" "$M/kde/unlord-layout.js")"
  [ "$TEMA" = nit ] && JS="${JS//unlord-rsu-emblema-1920x1080.png/unlord-rsu-fosc-1920x1080.png}"
  if $QDBUS org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$JS" >/dev/null 2>&1; then ok "Paneles, dock y fondo"
  else warn "No se pudo aplicar la distribución (hazlo desde una sesión de Plasma)"; fi
}
m11() { bash "$M/proyectos/instalar-iconos.sh" && ok "Iconos de proyectos (edita las rutas en modulos/proyectos/instalar-iconos.sh)"; }
m12() {
  if [ -d "$HOME/.vscode" ] || q code; then mkdir -p "$HOME/.vscode/extensions"; cp -r "$M/apps/vscode-unlord-theme" "$HOME/.vscode/extensions/unlord-theme"; ok "VS Code: Ctrl+K Ctrl+T → Unlord"; fi
  if [ -d "$HOME/.vscode-oss" ] || q codium; then mkdir -p "$HOME/.vscode-oss/extensions"; cp -r "$M/apps/vscode-unlord-theme" "$HOME/.vscode-oss/extensions/unlord-theme"; ok "VSCodium: Ctrl+K Ctrl+T → Unlord"; fi
  mkdir -p "$HOME/.config/btop/themes"; cp "$M"/apps/btop/*.theme "$HOME/.config/btop/themes/"; ok "btop: Esc → Options → Color theme → unlord"
  warn "Brave, Obsidian y Zotero son manuales: mira LEEME.txt (apartado APPS)"
}
m13() {
  if ! q spicetify; then warn "Falta spicetify: bash paquetes.sh (y abre Spotify una vez antes)"; return; fi
  mkdir -p "$HOME/.config/spicetify/Themes"; cp -r "$M/spotify/Unlord" "$HOME/.config/spicetify/Themes/"
  local SP="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"
  [ -d "$SP" ] && spicetify config spotify_path "$SP" >/dev/null
  spicetify config prefs_path "$HOME/.config/spotify/prefs" >/dev/null
  local cs=unlord; [ "$TEMA" = nit ] && cs=nit
  spicetify config current_theme Unlord color_scheme "$cs" >/dev/null && spicetify backup apply >/dev/null 2>&1 && ok "Spotify Unlord ($cs)" || warn "Spicetify no pudo aplicar: abre Spotify una vez, ciérralo y repite el módulo 13"
}

m14() {
  command -v rsvg-convert >/dev/null || { warn "Falta rsvg-convert: bash paquetes.sh (paquete librsvg)"; return; }
  mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
  install -m 755 "$M/fons-viu/rsu-fons-viu" "$HOME/.local/bin/"
  cp "$M"/fons-viu/rsu-fons-viu.{service,timer} "$HOME/.config/systemd/user/"
  m6 >/dev/null 2>&1   # fuentes
  systemctl --user daemon-reload && systemctl --user enable --now rsu-fons-viu.timer >/dev/null 2>&1
  if "$HOME/.local/bin/rsu-fons-viu" >/dev/null 2>&1; then ok "Fondo vivo activo (se actualiza cada 15 min)"
  else warn "Instalado, pero no ha podido descargar datos ahora; lo reintentará solo"; fi
  ok "Para quitarlo: systemctl --user disable --now rsu-fons-viu.timer"
}

m15() {
  mkdir -p "$HOME/.local/bin" "$HOME/.config/rsu-assistent"
  install -m 755 "$M/assistent/rsu-estat" "$HOME/.local/bin/"
  cp "$M/assistent/personalitat.txt" "$HOME/.config/rsu-assistent/"
  ok "rsu-estat instalado (resumen del mercado e informes para el asistente)"
  if command -v ollama >/dev/null; then
    systemctl is-active ollama >/dev/null 2>&1 || warn "Ollama no está en marcha: sudo systemctl enable --now ollama"
    ollama list 2>/dev/null | grep -q "qwen2.5:14b" || { echo "   Descargando el modelo (unos 9 GB, tarda un rato)..."; ollama pull qwen2.5:14b && ok "Modelo qwen2.5:14b listo"; }
  else warn "Falta Ollama: bash paquetes.sh"; fi
  flatpak info io.github.qwersyk.Newelle >/dev/null 2>&1 && ok "Newelle instalado" || warn "Falta Newelle: bash paquetes.sh"
  ok "Último paso a mano: mira el apartado ASISTENTE del LEEME.txt (5 minutos)"
}

# ---------- elección ----------
SEL=()
if [ $# -eq 0 ]; then
  printf '\n\e[1m RICE UNLORD / RSU · instalador\e[0m\n\n'
  for i in $(seq 1 $N); do printf '  %2d  %s\n' "$i" "${NOMS[$i]}"; done
  printf '\n  Escribe los números separados por espacios, o "todo": '; read -r R
  [ "$R" = todo ] && SEL=($(seq 1 $N)) || SEL=($R)
elif [ "$1" = todo ]; then SEL=($(seq 1 $N)); else SEL=("$@"); fi
SEL=($(printf "%s\n" "${SEL[@]}" | sort -n | uniq))
[ ${#SEL[@]} -eq 0 ] && { echo "Nada elegido."; exit 0; }
if [ -z "$TEMA" ]; then printf '  ¿Tema claro (Unlord) u oscuro (Nit)? [c/n]: '; read -r t; [ "${t,,}" = n ] && TEMA=nit || TEMA=claro; fi

backup
for i in "${SEL[@]}"; do
  [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -ge 1 ] && [ "$i" -le $N ] || { warn "Módulo $i no existe"; continue; }
  tit "$i · ${NOMS[$i]}"; "m$i" || warn "El módulo $i ha dado un error; el resto sigue"
done
printf '\n\e[1mHecho.\e[0m Cierra sesión y vuelve a entrar para verlo todo aplicado.\n'
printf 'Comprobar el sistema:  bash comprobar.sh\n'
printf 'Deshacer: copia los archivos de %s a ~/.config y cierra sesión.\n\n' "$BK"
