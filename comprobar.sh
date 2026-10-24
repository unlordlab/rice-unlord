#!/usr/bin/env bash
# ============================================================
#  RICE UNLORD — comprobación posinstalación
#  Revisa el sistema y el rice y dice qué falta y cómo arreglarlo.
#  No cambia nada. Uso: bash comprobar.sh
#  Guarda el informe en ~/comprobacion-unlord.txt (pásamelo si algo sale en rojo).
# ============================================================
set -u
OUT="$HOME/comprobacion-unlord.txt"; : > "$OUT"
V=0; R=0; A=0
q() { command -v "$1" >/dev/null 2>&1; }
pkg() { pacman -Q "$1" >/dev/null 2>&1; }
log() { printf '%s\n' "$*" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUT"; }
bien() { V=$((V+1)); printf '  \e[32m✔\e[0m %-34s %s\n' "$1" "${2:-}"; log "  OK    $1  ${2:-}"; }
mal()  { R=$((R+1)); printf '  \e[31m✘\e[0m %-34s \e[2m→ %s\e[0m\n' "$1" "$2"; log "  FALLA $1  → $2"; }
ojo()  { A=$((A+1)); printf '  \e[33m!\e[0m %-34s \e[2m→ %s\e[0m\n' "$1" "$2"; log "  AVISO $1  → $2"; }
sec()  { printf '\n\e[1;31m▌\e[0m\e[1m %s\e[0m\n' "$1"; log ""; log "== $1"; }
cfg()  { kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null; }
printf '\e[1m RICE UNLORD · comprobación  %s\e[0m\n' "$(date '+%d/%m/%Y %H:%M')"; log "Comprobación $(date) · $(uname -r)"

sec "SISTEMA"
bien "Kernel" "$(uname -r)"
[ "${XDG_SESSION_TYPE:-}" = wayland ] && bien "Sesión" "Wayland" || ojo "Sesión: ${XDG_SESSION_TYPE:-?}" "lo normal en Plasma 6 es Wayland"
if ip -br link | grep -q '^wl'; then
  ip -br link | grep '^wl' | grep -q UP && bien "Wifi (TX20U)" "$(ip -br link | awk '/^wl/{print $1; exit}')" || mal "Wifi" "la antena existe pero está apagada: revisa NetworkManager"
else ip -br link | grep -qE '^(en|eth)' && ojo "Wifi" "no hay interfaz wifi; ¿estás por cable? Si no, la guía: driver rtw89" || mal "Red" "no veo ni wifi ni cable"; fi
if ping -c1 -W3 1.1.1.1 >/dev/null 2>&1; then ping -c1 -W3 archlinux.org >/dev/null 2>&1 && bien "Internet" "con DNS" || mal "Internet" "hay conexión pero falla el DNS"
else mal "Internet" "sin conexión"; fi
if q nvidia-smi && nvidia-smi >/dev/null 2>&1; then bien "NVIDIA RTX 3060" "driver $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
else mal "NVIDIA" "el driver no responde: sudo pacman -S nvidia-open (o el de CachyOS: chwd -a)"; fi
if q wpctl && wpctl status 2>/dev/null | grep -q "Sinks:"; then
  S=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'"' '/node.description/{print $2; exit}'); bien "Audio" "${S:-salida por defecto}"
else mal "Audio" "PipeWire no responde"; fi
pkg easyeffects && bien "EasyEffects (ecualizador)" || ojo "EasyEffects" "sudo pacman -S easyeffects · importa tus presets de Equalizer APO"
if lsmod | grep -q '^xone'; then bien "Mando Xbox (xone)"
elif pkg xone-dkms || pkg xone-dkms-git; then ojo "Mando Xbox" "xone instalado pero sin cargar: reinicia o conecta el mando"
else mal "Mando Xbox" "paru -S xone-dkms (la guía lo explica)"; fi
if [ "$(findmnt -no FSTYPE /)" = btrfs ]; then
  bien "Sistema de archivos" "btrfs"
  if q snapper && snapper list-configs 2>/dev/null | grep -q root; then bien "Snapshots (snapper)" "$(snapper -c root list 2>/dev/null | tail -n +3 | wc -l) guardados"
  else mal "Snapshots" "sudo pacman -S cachyos-snapper-support (o snapper + snap-pac + grub-btrfs)"; fi
  pkg grub-btrfs && bien "Snapshots en el menú de GRUB" || ojo "grub-btrfs" "sin él no puedes arrancar un snapshot desde GRUB"
else ojo "Sistema de archivos" "$(findmnt -no FSTYPE /) (sin snapshots btrfs)"; fi
SB=$( (mokutil --sb-state 2>/dev/null || bootctl status 2>/dev/null | grep -i 'secure boot') | head -1)
case "$SB" in *nabled*) ojo "Secure Boot" "activado: si CachyOS arranca, perfecto (lo habrás firmado con sbctl)";;
  *isabled*) bien "Secure Boot" "desactivado (recuerda activarlo para CoD en Windows)";; *) ojo "Secure Boot" "no se pudo leer";; esac
if [ -f /etc/default/grub ]; then
  grep -q -E "^GRUB_DISABLE_OS_PROBER=['\"]?false" /etc/default/grub && bien "os-prober activado" || mal "os-prober" "Windows no saldrá en GRUB: pon GRUB_DISABLE_OS_PROBER=false"
  if sudo -n true 2>/dev/null; then sudo grep -qi windows /boot/grub/grub.cfg && bien "Windows en el menú de GRUB" || mal "Windows en GRUB" "sudo os-prober && sudo grub-mkconfig -o /boot/grub/grub.cfg"
  else ojo "Windows en GRUB" "no comprobado (necesita sudo); míralo al reiniciar"; fi
fi
L=$(df -h / | awk 'NR==2{print $4" libres de "$2}'); bien "Disco" "$L"
if q checkupdates; then U=$(checkupdates 2>/dev/null | wc -l); [ "$U" -gt 30 ] && ojo "Actualizaciones" "$U pendientes: sudo pacman -Syu" || bien "Actualizaciones" "$U pendientes"; fi

sec "APPS DE LA GUÍA"
for a in "brave:Brave" "bitwarden:Bitwarden" "steam:Steam" "obsidian:Obsidian" "zotero:Zotero" "localsend:LocalSend" "vlc:VLC"; do
  b=${a%%:*}; n=${a#*:}
  if q "$b" || flatpak list 2>/dev/null | grep -qi "$b"; then bien "$n"; else ojo "$n" "no instalada"; fi; done
q code || q codium || q zed || q zeditor && bien "Editor de código" || ojo "Editor" "VS Code, VSCodium o Zed"
q claude && bien "Claude Code" || ojo "Claude Code" "curl -fsSL https://claude.ai/install.sh | bash (o npm)"
LAY=$(cfg kxkbrc Layout LayoutList); VAR=$(cfg kxkbrc Layout VariantList)
if [[ "$VAR" == *intl* ]] || systemctl is-active keyd >/dev/null 2>&1; then bien "Acentos (sustituto AutoHotkey)" "${LAY:-} ${VAR:-keyd}"
else ojo "Acentos" "falta el teclado US intl AltGr o keyd (tarea pendiente de la guía)"; fi

sec "RICE"
[[ "$(cfg kdeglobals General ColorScheme)" == Unlord* ]] && bien "Colores" "$(cfg kdeglobals General ColorScheme)" || mal "Colores" "bash instalar.sh 2"
[ "$(cfg kdeglobals Icons Theme)" = Unlord ] && bien "Iconos" "Unlord" || mal "Iconos" "bash instalar.sh 3"
[ "$(cfg kcminputrc Mouse cursorTheme)" = Unlord-cursor ] && bien "Cursor" "Unlord" || mal "Cursor" "bash instalar.sh 4"
[ "$(cfg kdeglobals Sounds Theme)" = Unlord ] && bien "Sonidos" "Unlord" || mal "Sonidos" "bash instalar.sh 5"
fc-list | grep -q "Share Tech Mono" && fc-list | grep -q "Barlow Condensed" && bien "Fuentes" || mal "Fuentes" "bash instalar.sh 6"
fc-list | grep -qi "JetBrains Mono" && bien "Fuente de la terminal" "JetBrains Mono" || ojo "Fuente de terminal" "bash paquetes.sh"
case "$(cfg konsolerc 'Desktop Entry' DefaultProfile)" in Unlord.profile|UnlordNit.profile) true;; *) false;; esac && bien "Konsole" "perfil $(cfg konsolerc 'Desktop Entry' DefaultProfile | sed s/.profile//)" || mal "Konsole" "bash instalar.sh 7"
q starship && [ -f ~/.config/starship.toml ] && bien "starship" || mal "starship" "bash paquetes.sh y bash instalar.sh 7"
q fastfetch && [ -f ~/.config/fastfetch/config.jsonc ] && bien "fastfetch (logo RSU)" || mal "fastfetch" "bash paquetes.sh y bash instalar.sh 7"
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q org.unlord.rsu; then
  bien "Widget RSU" "instalado"
  J=$("$HOME/.local/bin/rsu-widget-dades" 2>/dev/null)
  if echo "$J" | grep -q '"error": ""' && echo "$J" | grep -q '"s":'; then bien "Widget RSU: precios" "llegan bien"
  else mal "Widget RSU: precios" "$(echo "$J" | grep -o '"error": "[^"]*"' | cut -d'"' -f4) · prueba: rsu-widget-dades"; fi
  grep -q org.unlord.rsu ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null && bien "Widget RSU en la barra" || ojo "Widget RSU" "instalado pero no está en la barra: clic derecho → Añadir elementos → RSU"
else mal "Widget RSU" "bash instalar.sh 8"; fi
[[ "$(cfg kscreenlockerrc Greeter WallpaperPlugin)" == org.kde.image ]] && grep -q bloqueig ~/.config/kscreenlockerrc 2>/dev/null && bien "Pantalla de bloqueo" || mal "Pantalla de bloqueo" "bash instalar.sh 9"
[ -d ~/.local/share/icons/unlord-projectes ] && bien "Iconos de proyectos" || ojo "Iconos de proyectos" "bash instalar.sh 11"
if q spicetify; then [ "$(spicetify config current_theme 2>/dev/null)" = Unlord ] && bien "Spotify" "tema Unlord" || ojo "Spotify" "bash instalar.sh 13"
else ojo "Spotify" "sin spicetify (opcional)"; fi
if systemctl --user is-enabled rsu-fons-viu.timer >/dev/null 2>&1; then
  [ -n "$(ls ~/.cache/rsu-fons-viu/fons-viu-*.png 2>/dev/null)" ] && bien "Fondo vivo" "activo" || mal "Fondo vivo" "sin imagen: ejecuta rsu-fons-viu y mira el error"
else ojo "Fondo vivo" "opcional: bash instalar.sh 14"; fi
flatpak info io.github.qwersyk.Newelle >/dev/null 2>&1 && q ollama && bien "Asistente Elia" "Newelle + Ollama" || ojo "Asistente" "opcional: bash paquetes.sh y bash instalar.sh 15"
pkg klassy && bien "Klassy (ventanas rectas)" || ojo "Klassy" "opcional: bash paquetes.sh"
grep -q unlord /etc/default/grub 2>/dev/null && bien "Tema de GRUB" || ojo "Tema de GRUB" "bash instalar-sistema.sh"
[ -f /etc/sddm.conf.d/zz-unlord.conf ] && bien "Tema de SDDM" || ojo "Tema de SDDM" "bash instalar-sistema.sh"
[ "$(plymouth-set-default-theme 2>/dev/null)" = unlord ] && bien "Plymouth" "unlord" || ojo "Plymouth" "bash instalar-sistema.sh"

printf '\n  \e[32m%d bien\e[0m · \e[33m%d avisos\e[0m · \e[31m%d por arreglar\e[0m\n' $V $A $R
printf '  Informe guardado en %s\n\n' "$OUT"; log ""; log "$V bien · $A avisos · $R por arreglar"
