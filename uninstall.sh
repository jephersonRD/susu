#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
#  susu — desinstalador
#
#  Borra TODA la personalización instalada por susu y deja Termux por defecto:
#    · Elimina ~/.zshrc, configs de fastfetch/htop/yazi/starship y ~/.ssh/config
#    · Elimina ~/.termux (colores, fuente y teclas) y el shell por defecto
#    · Elimina los plugins de zsh clonados y el estado en ~/.config/susu
#    · Restaura tus configs anteriores si hay backup de la instalación
#    · Desinstala solo los paquetes que susu tuvo que instalar
#    · Ofrece un backup rápido antes de borrar
#    · NUNCA toca claves privadas (~/.ssh/id_*) ni known_hosts
#
#  Equivale a la opción 3 del menú de install.sh.
# =============================================================================
set -euo pipefail

STATE_DIR="$HOME/.config/susu"
LANG_FILE="$STATE_DIR/lang"
PKGS_FILE="$STATE_DIR/installed_pkgs"
BACKUP_FILE="$STATE_DIR/last_backup"
BACKUP_ROOT="$HOME/.susu-backup"
PKGS=(zsh starship eza bat fzf zoxide git htop yazi fastfetch openssh)
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
ZSH_PLUGINS=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

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

# Restaura desde el backup que guardó install.sh (si existe)
restore_last_backup() {   # <dir backup>
  local bdir="$1"
  [[ -n "$bdir" && -d "$bdir" ]] || return 1
  local -a rels=(
    ".zshrc"
    ".config/fastfetch"
    ".config/htop"
    ".config/yazi"
    ".config/starship.toml"
    ".ssh/config"
    ".termux/termux.properties"
    ".termux/colors.properties"
    ".termux/font.ttf"
  )
  local rel n=0
  for rel in "${rels[@]}"; do
    [[ -e "$bdir$HOME/$rel" ]] || continue
    mkdir -p "$(dirname "$HOME/$rel")"
    cp -a "$bdir$HOME/$rel" "$HOME/$rel"
    n=$(( n + 1 ))
  done
  (( n > 0 ))
}

# =============================================================================
#  Flujo principal
# =============================================================================
main() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]] \
    || die "Este desinstalador solo funciona dentro de Termux."

  # Paquetes a quitar: solo los que susu instaló (si hay registro)
  local -a pkgs=("${PKGS[@]}")
  if [[ -f "$PKGS_FILE" ]]; then
    mapfile -t pkgs < <(grep -v '^[[:space:]]*$' "$PKGS_FILE" || true)
  fi

  # Backup de la instalación (para restaurar configs previas)
  local last_backup=""
  [[ -f "$BACKUP_FILE" ]] && read -r last_backup < "$BACKUP_FILE" || true

  printf '\n'
  if [[ "$LANG_CODE" == "en" ]]; then
    printf '  %s%s%s\n' "$BOLD" "susu — full uninstall" "$N"
    printf '  This will remove ALL the customization installed by susu and restore Termux defaults:\n'
    printf '  %s· ~/.zshrc, fastfetch/htop/yazi/starship configs, ~/.ssh/config, ~/.config/susu%s\n' "$P" "$N"
    printf '  %s· ~/.termux colors, font and extra keys, plus the default shell%s\n' "$P" "$N"
    printf '  %s· zsh plugins and packages: %s%s\n' "$P" "${pkgs[*]}" "$N"
    [[ -n "$last_backup" && -d "$last_backup" ]] \
      && printf '  %s· Your previous configs will be restored from %s%s\n' "$P" "$last_backup" "$N"
    printf '  %s⚠ Your private keys (~/.ssh/id_*) and known_hosts are NEVER touched.%s\n\n' "$Y" "$N"
    CONFIRM_WORD="yes"
    PROMPT="Type «yes» to confirm:"
  else
    printf '  %s%s%s\n' "$BOLD" "susu — desinstalación completa" "$N"
    printf '  Esto eliminará TODA la personalización instalada por susu y dejará Termux por defecto:\n'
    printf '  %s· ~/.zshrc, configs de fastfetch/htop/yazi/starship, ~/.ssh/config, ~/.config/susu%s\n' "$P" "$N"
    printf '  %s· ~/.termux (colores, fuente, teclas) y el shell por defecto%s\n' "$P" "$N"
    printf '  %s· Plugins de zsh y paquetes: %s%s\n' "$P" "${pkgs[*]}" "$N"
    [[ -n "$last_backup" && -d "$last_backup" ]] \
      && printf '  %s· Tus configs anteriores se restaurarán desde %s%s\n' "$P" "$last_backup" "$N"
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
        _bkp "$HOME/.config/yazi"; _bkp "$HOME/.config/starship.toml"; _bkp "$HOME/.ssh/config"
        _bkp "$HOME/.termux/termux.properties"; _bkp "$HOME/.termux/colors.properties"
        _bkp "$HOME/.termux/font.ttf"
        ok "Backup: $BACKUP_DIR"
        ;;
    esac
  fi

  # 1) Borrar SOLO lo instalado por susu (nunca claves privadas)
  rm -f  "$HOME/.zshrc"
  rm -rf "$HOME/.config/fastfetch" "$HOME/.config/htop" "$HOME/.config/yazi"
  rm -f  "$HOME/.config/starship.toml"
  rm -f  "$HOME/.ssh/config"          # solo el config, NO ~/.ssh completo
  rm -f  "$HOME/.termux/termux.properties" "$HOME/.termux/colors.properties"
  rm -f  "$HOME/.termux/font.ttf" "$HOME/.termux/shell"
  rm -rf "${ZSH_PLUGINS[@]/#/$ZSH_PLUGIN_DIR/}"
  rmdir "$ZSH_PLUGIN_DIR" 2>/dev/null || true
  ok "~/.zshrc · ~/.config/{fastfetch,htop,yazi,starship.toml} · ~/.ssh/config · ~/.termux ✘"

  # 2) Restaurar configs previas (si hay backup de la instalación)
  if [[ -n "$last_backup" ]] && restore_last_backup "$last_backup"; then
    ok "Configs anteriores restauradas desde $last_backup"
  fi

  # 3) Restaurar shell por defecto
  if command -v chsh >/dev/null 2>&1; then
    chsh -s bash 2>/dev/null || rm -f "$HOME/.termux/shell"
  else
    rm -f "$HOME/.termux/shell"
  fi
  ok "Shell por defecto restaurado (bash)"

  rm -rf "$STATE_DIR"

  # 4) Termux recarga colores/fuente/teclas al instante
  command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings >/dev/null 2>&1 || true

  # 5) Desinstalar solo los paquetes que instaló susu
  if (( ${#pkgs[@]} )); then
    hide_cursor
    printf '  %s⠋%s pkg uninstall %s' "$P" "$N" "${pkgs[*]}"
    pkg uninstall -y "${pkgs[@]}" &>/dev/null || true
    show_cursor
    printf '\r  %s✔%s pkg uninstall %s   \n' "$G" "$N" "${pkgs[*]}"
  fi

  printf '\n  %s✔ %s%s\n' "$G" \
    "$([[ "$LANG_CODE" == "en" ]] && echo "Uninstall complete. Restart Termux to apply changes." || echo "Borrado completado. Reinicia Termux para aplicar los cambios.")" "$N"
  printf '  %s➜ %s%s\n\n' "$D" \
    "$([[ "$LANG_CODE" == "en" ]] && echo "Your private keys were NOT touched." || echo "Tus claves privadas NO se han tocado.")" "$N"
}

main "$@"
