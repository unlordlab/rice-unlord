#!/usr/bin/env bash
# Paquetes que usa el rice. Pide la contraseña (sudo) para pacman.
set -e
OFI=(fastfetch starship btop ttf-jetbrains-mono ttf-ibm-plex spotify-launcher librsvg flatpak ollama-cuda)
AUR=(klassy koi spicetify-cli)
echo "Repositorios oficiales: ${OFI[*]}"
echo "AUR (con paru):         ${AUR[*]}"
read -rp "¿Instalar? [s/N] " r; [ "${r,,}" = s ] || exit 0
sudo pacman -S --needed "${OFI[@]}"
if command -v paru >/dev/null; then paru -S --needed "${AUR[@]}"
else echo "No encuentro paru: sudo pacman -S paru  y vuelve a ejecutar este script."; fi
sudo systemctl enable --now ollama
flatpak install -y flathub io.github.qwersyk.Newelle || echo "Newelle: instálalo desde Discover (busca Newelle)"
echo "Listo. Spotify: ábrelo una vez e inicia sesión antes del módulo 13 de instalar.sh."
