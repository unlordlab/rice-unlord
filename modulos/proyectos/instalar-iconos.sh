#!/usr/bin/env bash
# Iconos de escritorio para tus proyectos (Unlord / RSU)
# Uso: bash instalar-iconos.sh
# Crea lanzadores en el Escritorio solo para los proyectos cuya carpeta existe.
# Edita las rutas de abajo si tus proyectos están en otro sitio.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ICONS="$HOME/.local/share/icons/unlord-projectes"
DESK="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
mkdir -p "$ICONS" "$DESK"
cp "$DIR"/png/*.png "$ICONS/"

# ---------- RUTAS (edítalas si hace falta) ----------
RSU_TERMINAL="$HOME/rsu-terminal-web"
HUMANIZER="$HOME/manuscript-humanizer"
HUMANIZER_SKILL="$HOME/humanizer-skill"
BLOG="$HOME/unlord-blog"
BLOG_URL="https://unlordl4b.pages.dev"
MIRROR="$HOME/algorithmic-mirror"
INFORMES="$HOME/projectes/rsu-informes"
NEWS="$HOME/projectes/rsu-news-feed"
CANSLIM="$HOME/projectes/can-slim-scanner"
BRAIN="$HOME/projectes/unlord-l4b-brain"
VIDEO="$DESK/Video RSU"
# ----------------------------------------------------

# lanzador <archivo> <nombre> <icono> <Exec> <carpeta> [acciones extra...]
launcher() {
  local file="$1" name="$2" icon="$3" exec="$4" folder="$5"; shift 5
  local out="$DESK/$file.desktop"
  {
    echo "[Desktop Entry]"
    echo "Type=Application"
    echo "Name=$name"
    echo "Icon=$ICONS/$icon-512.png"
    echo "Exec=$exec"
    echo "Path=$folder"
    echo "Terminal=false"
    echo "Actions=terminal;carpeta;$*"
    echo
    echo "[Desktop Action terminal]"
    echo "Name=Obrir terminal aquí"
    echo "Exec=konsole --workdir \"$folder\""
    echo
    echo "[Desktop Action carpeta]"
    echo "Name=Obrir la carpeta"
    echo "Exec=dolphin \"$folder\""
  } > "$out"
  chmod +x "$out"
  echo "  ✓ $name"
}
extra() { printf '\n[Desktop Action %s]\nName=%s\nExec=%s\n' "$2" "$3" "$4" >> "$DESK/$1.desktop"; }
have() { [ -d "$1" ]; }
skip() { echo "  · $1: no encuentro $2 (edita la ruta en el script)"; }

echo "Creando iconos en $DESK"
have "$RSU_TERMINAL" && launcher "rsu-terminal" "RSU Terminal" "rsu-terminal" "code \"$RSU_TERMINAL\"" "$RSU_TERMINAL" || skip "RSU Terminal" "$RSU_TERMINAL"
if have "$HUMANIZER"; then
  launcher "ai-humanizer" "AI Humanizer" "ai-humanizer" "code \"$HUMANIZER\"" "$HUMANIZER" "skill;"
  extra "ai-humanizer" "skill" "Obrir humanizer-skill" "code \"$HUMANIZER_SKILL\""
else skip "AI Humanizer" "$HUMANIZER"; fi
if have "$BLOG"; then
  launcher "ul4b" "UL4B · Blog" "ul4b" "xdg-open $BLOG_URL" "$BLOG" "codi;hugo;"
  extra "ul4b" "codi" "Obrir el codi (VS Code)" "code \"$BLOG\""
  extra "ul4b" "hugo" "Previsualitzar en local (hugo server)" "konsole --workdir \"$BLOG\" -e hugo server -D"
else skip "UL4B" "$BLOG"; fi
have "$MIRROR"   && launcher "algorithmic-mirror" "Algorithmic Mirror" "algorithmic-mirror" "code \"$MIRROR\"" "$MIRROR" || skip "Algorithmic Mirror" "$MIRROR"
have "$INFORMES" && launcher "rsu-informes" "RSU · Informes" "rsu-informes" "dolphin \"$INFORMES\"" "$INFORMES" || skip "RSU Informes" "$INFORMES"
have "$NEWS"     && launcher "rsu-news" "RSU · News Feed" "rsu-news" "code \"$NEWS\"" "$NEWS" || skip "RSU News Feed" "$NEWS"
have "$CANSLIM"  && launcher "canslim" "CAN SLIM Scanner" "canslim" "code \"$CANSLIM\"" "$CANSLIM" || skip "CAN SLIM Scanner" "$CANSLIM"
have "$BRAIN"    && launcher "l4b-brain" "L4B Brain" "l4b-brain" "code \"$BRAIN\"" "$BRAIN" || skip "L4B Brain" "$BRAIN"
have "$VIDEO"    && launcher "video-rsu" "Vídeo · Manifest RSU" "video-rsu" "dolphin \"$VIDEO\"" "$VIDEO" || skip "Vídeo RSU" "$VIDEO"
echo "Fet. Si KDE pregunta si confías en el lanzador la primera vez, acepta."
