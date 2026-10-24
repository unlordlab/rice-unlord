#!/usr/bin/env bash
# ============================================================
#  RICE UNLORD — partes de sistema (necesitan sudo)
#  GRUB (menú de arranque) · SDDM (inicio de sesión) · Plymouth (animación)
#  Pregunta antes de cada una y guarda copia de lo que toca.
# ============================================================
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; S="$D/modulos/sistema"
si() { read -rp "   $1 [s/N] " r; [ "${r,,}" = s ]; }
ok() { printf '   \e[32m✔\e[0m %s\n' "$*"; }
warn() { printf '   \e[33m!\e[0m %s\n' "$*"; }
sudo -v || exit 1

printf '\n\e[1m1 · GRUB\e[0m\n'
if [ ! -f /etc/default/grub ]; then warn "No hay GRUB (¿elegiste otro gestor de arranque?). Me lo salto."
elif si "¿Aplicar el tema de GRUB?"; then
  sudo cp -n /etc/default/grub /etc/default/grub.bak-unlord
  sudo rm -rf /usr/share/grub/themes/unlord; sudo cp -r "$S/grub-unlord" /usr/share/grub/themes/unlord
  T='GRUB_THEME="/usr/share/grub/themes/unlord/theme.txt"'
  if grep -q '^#\?GRUB_THEME=' /etc/default/grub; then sudo sed -i "s|^#\?GRUB_THEME=.*|$T|" /etc/default/grub; else echo "$T" | sudo tee -a /etc/default/grub >/dev/null; fi
  if grep -q '^#\?GRUB_GFXMODE=' /etc/default/grub; then sudo sed -i 's|^#\?GRUB_GFXMODE=.*|GRUB_GFXMODE=1920x1080,auto|' /etc/default/grub; else echo 'GRUB_GFXMODE=1920x1080,auto' | sudo tee -a /etc/default/grub >/dev/null; fi
  sudo sed -i 's|^GRUB_TERMINAL_OUTPUT=console|#GRUB_TERMINAL_OUTPUT=console|' /etc/default/grub
  grep -q '^GRUB_DISABLE_OS_PROBER=false' /etc/default/grub || warn "OJO: para que salga Windows, GRUB_DISABLE_OS_PROBER=false debe estar en /etc/default/grub (la guía lo explica)"
  sudo grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | grep -iE "windows|error|found theme" || true
  ok "GRUB listo (copia: /etc/default/grub.bak-unlord)"
fi

printf '\n\e[1m2 · SDDM (inicio de sesión)\e[0m\n'
if si "¿Instalar el tema de SDDM?"; then
  sudo rm -rf /usr/share/sddm/themes/unlord; sudo cp -r "$S/sddm-unlord" /usr/share/sddm/themes/unlord
  if command -v sddm-greeter-qt6 >/dev/null && si "¿Verlo antes en una ventana de prueba? (ciérrala para seguir)"; then
    sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/unlord >/dev/null 2>&1 || true; fi
  if si "¿Activarlo?"; then
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=unlord\n' | sudo tee /etc/sddm.conf.d/zz-unlord.conf >/dev/null
    ok "SDDM listo · para quitarlo: sudo rm /etc/sddm.conf.d/zz-unlord.conf"
  fi
fi

printf '\n\e[1m3 · Plymouth (animación de arranque)\e[0m\n'
if ! command -v plymouth-set-default-theme >/dev/null; then warn "Plymouth no está instalado. Me lo salto."
elif si "¿Aplicar la animación Unlord?"; then
  ANT=$(plymouth-set-default-theme 2>/dev/null || echo cachyos)
  sudo rm -rf /usr/share/plymouth/themes/unlord; sudo cp -r "$S/plymouth-unlord" /usr/share/plymouth/themes/unlord
  sudo plymouth-set-default-theme unlord
  if command -v mkinitcpio >/dev/null; then sudo mkinitcpio -P >/dev/null 2>&1 && ok "initramfs regenerado (mkinitcpio)"
  elif command -v dracut >/dev/null; then sudo dracut --regenerate-all --force >/dev/null 2>&1 && ok "initramfs regenerado (dracut)"; fi
  grep -q 'splash' /proc/cmdline || warn "Falta 'splash' en GRUB_CMDLINE_LINUX_DEFAULT (/etc/default/grub); añádelo y ejecuta sudo grub-mkconfig -o /boot/grub/grub.cfg"
  ok "Plymouth listo · para volver: sudo plymouth-set-default-theme $ANT && sudo mkinitcpio -P"
fi
printf '\nReinicia para verlo todo. Si algo falla, la guía tiene cómo deshacer cada parte.\n'
