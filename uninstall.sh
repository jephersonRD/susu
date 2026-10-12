#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# susu — desinstalador
# Restaura el backup más reciente creado por install.sh y elimina
# la configuración instalada que no existiera antes.
# NO desinstala paquetes (zsh, htop, yazi, fastfetch, openssh).
# =============================================================================
set -euo pipefail

BACKUP_ROOT="$HOME/.susu-backup"
VERSION_FILE="$HOME/.config/susu/version"

P=$'\e[38;5;141m'; G=$'\e[38;5;114m'; Y=$'\e[38;5;220m'; R=$'\e[38;5;203m'
B=$'\e[38;5;111m'; D=$'\e[2m'; N=$'\e[0m'

ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$1"; }
info() { printf '  %s➜%s %s\n' "$B" "$N" "$1"; }
die()  { printf '  %s✘ %s%s\n' "$R" "$1" "$N" >&2; exit 1; }

printf '\n  %s⬇ susu%s — desinstalador\n\n' "$P" "$N"

# ── Solo Termux ──────────────────────────────────────────────────────────────
[[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]] \
  || die "Este script solo funciona dentro de Termux."

# ── Buscar el backup más reciente ────────────────────────────────────────────
LATEST=$(ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | sort | tail -n1 || true)
[[ -n "$LATEST" ]] || die "No se encontró ningún backup en $BACKUP_ROOT"
info "Restaurando backup: ${LATEST%/}"

printf '  %s¿Continuar? Esto sobrescribirá las configs actuales. (s/n)%s ' "$B" "$N"
read -r ans
[[ $ans == [sSyY] ]] || { info "Cancelado."; exit 0; }

# ── Restaurar ────────────────────────────────────────────────────────────────
# Objetivos que maneja el instalador
TARGETS=(
  "$HOME/.zshrc"
  "$HOME/.config/fastfetch"
  "$HOME/.config/htop"
  "$HOME/.config/yazi"
  "$HOME/.ssh/config"
)
for t in "${TARGETS[@]}"; do
  rel="${t#"$HOME"}"           # ruta relativa al HOME
  if [[ -e "$LATEST$rel" ]]; then
    mkdir -p "$(dirname "$t")"
    cp -a "$LATEST$rel" "$t"
    ok "Restaurado: $t"
  else
    # No existía antes de la instalación → eliminar lo instalado
    rm -rf "$t"
    info "Eliminado (no existía antes): $t"
  fi
done

# ── Limpiar estado del instalador ────────────────────────────────────────────
rm -f "$VERSION_FILE"
rmdir --ignore-fail-on-non-empty "$HOME/.config/susu" 2>/dev/null || true

printf '\n  %s✔ Desinstalación completada.%s' "$G" "$N"
printf '  %sEl backup se conserva en %s por si acaso.%s' "$D" "$LATEST" "$N"
printf '  %sNota: los paquetes NO se desinstalan automáticamente.%s\n\n' "$D" "$N"
