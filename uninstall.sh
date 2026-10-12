#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
#  susu — desinstalador
#
#  Borra TODA la personalización instalada por susu y deja Termux por defecto:
#    · Elimina ~/.zshrc, configs de fastfetch/htop/yazi y ~/.ssh/config
#    · Elimina el estado en ~/.config/susu
#    · Restaura el shell por defecto (chsh -s bash)
#    · Desinstala los paquetes zsh, htop, yazi, fastfetch y openssh
#    · Ofrece un backup rápido antes de borrar
#    · NUNCA toca claves privadas (~/.ssh/id_*) ni known_hosts
#
#  Equivale a la opción 3 del menú de install.sh.
# =============================================================================
set -euo pipefail

STATE_DIR="$HOME/.config/susu"
LANG_FILE="$STATE_DIR/lang"
BACKUP_ROOT="$HOME/.susu-backup"
PKGS=(zsh htop yazi fastfetch openssh)

# ── Colores ──────────────────────────────────────────────────────────────────
P=$'\e[38;5;141m'; B=$'\e[38;5;111m'; G=$'\e[38;5;114m'; Y=$'\e[38;5;220m'
R=$'\e[38;5;203m'; D=$'\e[2m'; BOLD=$'\e[1m'; N=$'\e[0m'

ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$1"; }
info() { printf '  %s➜%s %s\n' "$B" "$N" "$1"; }
warn() { printf '  %s⚠%s %s\n' "$Y" "$N" "$1"; }
die()  { printf '  %s✘%s %s\n' "$R" "$N" "$1" >&2; exit 1; }

hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }
on_exit() { show_cursor; return 0; }
trap on_exit EXIT
trap 'exit 130' INT TERM

# ask <var> <prompt> — lee de /dev/tty (compatible con curl | bash)
ask() {
  local __var="$1" __prompt="${2:-}"
  printf '%s ' "$__prompt"
  [[ -r /dev/tty ]] || return 1
  IFS= read -r "$__var" < /dev/tty || return 1
}

# ── Idioma: reutiliza la elección guardada por install.sh (ES por defecto) ──
LANG_CODE="es"
[[ -f "$LANG_FILE" ]] && LANG_CODE=$(cat "$LANG_FILE" 2>/dev/null || echo es)

_bkp() {
  [[ -e "$1" ]] || return 0
  mkdir -p "$BACKUP_DIR$(dirname "$1")"
  cp -a "$1" "$BACKUP_DIR$1"
}

# =============================================================================
#  Flujo principal
# =============================================================================
main() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]] \
    || die "Este desinstalador solo funciona dentro de Termux."

  printf '\n'
  if [[ "$LANG_CODE" == "en" ]]; then
    printf '  %s%s%s\n' "$BOLD" "susu — full uninstall" "$N"
    printf '  This will remove ALL the customization installed by susu and restore Termux defaults:\n'
    printf '  %s· ~/.zshrc, fastfetch/htop/yazi configs, ~/.ssh/config, ~/.config/susu%s\n' "$P" "$N"
    printf '  %s· Packages: %s%s\n' "$P" "${PKGS[*]}" "$N"
    printf '  %s· Default shell restored (bash)%s\n' "$P" "$N"
    printf '  %s⚠ Your private keys (~/.ssh/id_*) and known_hosts are NEVER touched.%s\n\n' "$Y" "$N"
    CONFIRM_WORD="yes"
    PROMPT="Type «yes» to confirm:"
  else
    printf '  %s%s%s\n' "$BOLD" "susu — desinstalación completa" "$N"
    printf '  Esto eliminará TODA la personalización instalada por susu y dejará Termux por defecto:\n'
    printf '  %s· ~/.zshrc, configs de fastfetch/htop/yazi, ~/.ssh/config, ~/.config/susu%s\n' "$P" "$N"
    printf '  %s· Paquetes: %s%s\n' "$P" "${PKGS[*]}" "$N"
    printf '  %s· Shell por defecto restaurado (bash)%s\n' "$P" "$N"
    printf '  %s⚠ Tus claves privadas (~/.ssh/id_*) y known_hosts NUNCA se tocan.%s\n\n' "$Y" "$N"
    CONFIRM_WORD="si"
    PROMPT="Escribe «si» para confirmar:"
  fi

  local ans=""
  ask ans "  $PROMPT" || die "Necesita una terminal interactiva / needs an interactive terminal."
  if [[ "$ans" != "$CONFIRM_WORD" ]]; then
    info "Cancelado. No se ha tocado nada. / Aborted. Nothing changed."
    exit 0
  fi

  # Backup rápido opcional
  local b=""
  if ask b "  ¿Backup rápido antes de borrar? / Quick backup first? (s/n · y/n):"; then
    case "$b" in
      s|S|y|Y)
        BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
        _bkp "$HOME/.zshrc"; _bkp "$HOME/.config/fastfetch"; _bkp "$HOME/.config/htop"
        _bkp "$HOME/.config/yazi"; _bkp "$HOME/.ssh/config"
        ok "Backup: $BACKUP_DIR"
        ;;
    esac
  fi

  # 1) Borrar SOLO lo instalado por susu (nunca claves privadas)
  rm -f  "$HOME/.zshrc"
  rm -rf "$HOME/.config/fastfetch" "$HOME/.config/htop" "$HOME/.config/yazi"
  rm -f  "$HOME/.ssh/config"
  rm -rf "$STATE_DIR"
  ok "~/.zshrc · ~/.config/{fastfetch,htop,yazi} · ~/.ssh/config ✘"

  # 2) Restaurar shell por defecto
  if command -v chsh >/dev/null 2>&1; then
    chsh -s bash 2>/dev/null || true
    ok "chsh -s bash"
  fi

  # 3) Desinstalar paquetes instalados por susu
  hide_cursor
  printf '  %s⠋%s pkg uninstall %s' "$P" "$N" "${PKGS[*]}"
  pkg uninstall -y "${PKGS[@]}" &>/dev/null || true
  show_cursor
  printf '\r  %s✔%s pkg uninstall %s   \n' "$G" "$N" "${PKGS[*]}"

  printf '\n  %s✔ %s%s\n' "$G" \
    "$([[ "$LANG_CODE" == "en" ]] && echo "Uninstall complete. Restart Termux to apply changes." || echo "Borrado completado. Reinicia Termux para aplicar los cambios.")" "$N"
  printf '  %s➜ %s%s\n\n' "$D" \
    "$([[ "$LANG_CODE" == "en" ]] && echo "Your private keys were NOT touched." || echo "Tus claves privadas NO se han tocado.")" "$N"
}

main "$@"
