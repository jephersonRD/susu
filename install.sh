#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# My-termux-config — instalador de una línea
#
#   curl -fsSL https://raw.githubusercontent.com/jephersonRD/My-termux-config/main/install.sh | bash
#
# - Detecta la última versión publicada (API de GitHub, sin jq).
# - Descarga el .tar.gz con barra de progreso REAL (Content-Length).
# - Instala paquetes faltantes con pkg (idempotente).
# - Hace backup de configs previas antes de sobrescribir.
# - Guarda la versión instalada en ~/.config/my-termux-config/version.
# =============================================================================
set -euo pipefail

# ── Constantes ───────────────────────────────────────────────────────────────
REPO="jephersonRD/My-termux-config"
API_LATEST="https://api.github.com/repos/${REPO}/releases/latest"
RAW_MAIN="https://codeload.github.com/${REPO}/tar.gz/refs/heads/main"

STATE_DIR="$HOME/.config/my-termux-config"
VERSION_FILE="$STATE_DIR/version"
BACKUP_ROOT="$HOME/.my-termux-config-backup"

PKGS=(zsh htop yazi fastfetch openssh)
BAR_W=20

# ── Colores ANSI ─────────────────────────────────────────────────────────────
P=$'\e[38;5;141m'   # lila
B=$'\e[38;5;111m'   # azul pastel
G=$'\e[38;5;114m'   # verde
Y=$'\e[38;5;220m'   # amarillo
R=$'\e[38;5;203m'   # rojo
D=$'\e[2m'          # tenue
BOLD=$'\e[1m'
N=$'\e[0m'

# ── Utilidades de salida ─────────────────────────────────────────────────────
ok()   { printf '  %s✔%s %s\n'  "$G" "$N" "$1"; }
info() { printf '  %s➜%s %s\n'  "$B" "$N" "$1"; }
warn() { printf '  %s⚠%s %s\n'  "$Y" "$N" "$1"; }
die()  { printf '  %s✘ %s%s\n' "$R" "$1" "$N" >&2; exit 1; }

hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }

# Restaura el cursor siempre, incluso si el script falla o se interrumpe
on_exit() { show_cursor; [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"; }
on_err()  { show_cursor; printf '\n  %s✘ Error en la línea %s. Instalación abortada.%s\n' "$R" "$1" "$N" >&2; }
trap on_exit EXIT
trap 'on_err $LINENO' ERR
trap 'exit 130' INT TERM

# =============================================================================
#  0. Comprobaciones del entorno
# =============================================================================
check_environment() {
  # Solo Termux: $PREFIX debe existir y apuntar al entorno de Termux
  [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]] \
    || die "Este instalador solo funciona dentro de Termux (Android)."
  command -v pkg  >/dev/null 2>&1 || die "No se encontró 'pkg' (¿es Termux?)."
  command -v curl >/dev/null 2>&1 || die "Falta 'curl'. Instálalo con: pkg install curl"
}

check_internet() {
  curl -fsI -m 10 https://github.com >/dev/null 2>&1 \
    || die "Sin conexión a internet o github.com no responde."
}

# =============================================================================
#  1. Versión remota (API de GitHub, parseada con grep/sed, sin jq)
# =============================================================================
fetch_remote_version() {
  local json
  json=$(curl -fsSL -m 20 "$API_LATEST" 2>/dev/null) || json=""

  TAG=$(printf '%s' "$json" | grep -m1 '"tag_name"' \
      | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)

  if [[ -z "$TAG" ]]; then
    warn "Aún no hay releases publicados — se usará la rama main."
    TAG="main"
    DOWNLOAD_URL="$RAW_MAIN"
  else
    # URL del asset .tar.gz adjunto al release (lo genera el workflow)
    ASSET_URL=$(printf '%s' "$json" | grep '"browser_download_url"' \
        | grep '\.tar\.gz' | head -n1 \
        | sed -E 's/.*"(https:[^"]+\.tar\.gz)".*/\1/' || true)
    if [[ -n "$ASSET_URL" ]]; then
      DOWNLOAD_URL="$ASSET_URL"
    else
      # Respaldo: tarball automático del tag
      DOWNLOAD_URL="https://codeload.github.com/${REPO}/tar.gz/refs/tags/${TAG}"
      warn "El release no tiene .tar.gz adjunto; se usará el tarball del tag."
    fi
  fi
}

# =============================================================================
#  2. Versión instalada
# =============================================================================
installed_version() {
  [[ -f "$VERSION_FILE" ]] && cat "$VERSION_FILE" || printf 'no instalada'
}

# =============================================================================
#  3. Descarga con barra de progreso REAL (Content-Length)
# =============================================================================
fmt_mb() { awk -v b="${1:-0}" 'BEGIN { printf "%.1f", b / 1048576 }'; }

remote_size() {   # Content-Length de la URL (última cabecera tras redirects)
  curl -fsIL -m 15 "$1" 2>/dev/null \
    | grep -i '^content-length:' | tail -n1 \
    | tr -d '\r' | awk '{print $2}' || true
}

draw_bar() {  # descargados total velocidad(bytes/s)
  local size=$1 total=$2 speed=$3
  local pct=0 filled=0 i bar=""
  if (( total > 0 )); then
    pct=$(( size * 100 / total )); (( pct > 100 )) && pct=100
    filled=$(( pct * BAR_W / 100 ))
  fi
  for (( i = 0; i < BAR_W; i++ )); do
    (( i < filled )) && bar+="█" || bar+="░"
  done
  printf '\r  %s[%s]%s %3d%%  %s/%s MB  %s MB/s   ' \
    "$P" "$bar" "$N" "$pct" \
    "$(fmt_mb "$size")" "$(fmt_mb "$total")" "$(fmt_mb "$speed")"
}

download_with_progress() {  # url destino
  local url=$1 out=$2 total
  total=$(remote_size "$url"); total=${total:-0}

  printf '\n  %s⬇ My-termux-config%s\n' "$BOLD$P" "$N"
  printf '  Versión actual: %s  →  Nueva: %s\n' "$CUR_DISPLAY" "$TAG_DISPLAY"
  if (( total > 0 )); then
    printf '  Peso: %s MB\n\n' "$(fmt_mb "$total")"
  else
    printf '  Peso: %s(desconocido)%s\n\n' "$D" "$N"
  fi

  hide_cursor
  curl -fsSL -o "$out" "$url" & local pid=$!
  local size=0 prev=0 t_prev=$SECONDS speed=0 dt
  while kill -0 "$pid" 2>/dev/null; do
    size=$(stat -c %s "$out" 2>/dev/null || echo 0)
    dt=$(( SECONDS - t_prev ))
    if (( dt >= 1 )); then
      speed=$(( (size - prev) / dt )); prev=$size; t_prev=$SECONDS
    fi
    draw_bar "$size" "$total" "$speed"
    sleep 0.2
  done
  if wait "$pid"; then
    size=$(stat -c %s "$out" 2>/dev/null || echo 0)
    show_cursor
    # El archivo debe ser un .tar.gz válido (y no una página de error)
    if ! tar -tzf "$out" &>/dev/null; then
      die "El paquete descargado no es válido (¿existe el repo y el release?)."
    fi
    (( total > 0 )) || total=$size
    draw_bar "$size" "$total" "$speed"; printf '\n\n'
    ok "Descarga completada"
  else
    show_cursor
    die "La descarga falló. Revisa tu conexión e inténtalo de nuevo."
  fi
}

# =============================================================================
#  4. Spinner con el mismo estilo para pasos largos
# =============================================================================
run_with_spinner() {   # "mensaje" cmd args...
  local msg=$1; shift
  hide_cursor
  "$@" &>/dev/null & local pid=$!
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏) i=1
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r  %s%s%s %s' "$P" "${frames[i]}" "$N" "$msg"
    (( i = i % ${#frames[@]} + 1 )); sleep 0.1
  done
  show_cursor
  if wait "$pid"; then
    printf '\r  %s✔%s %s   \n' "$G" "$N" "$msg"
  else
    printf '\r  %s✘%s %s %s(falló)%s\n' "$R" "$N" "$msg" "$D" "$N"
    return 1
  fi
}

# =============================================================================
#  5. Paquetes: instala SOLO los que falten (idempotente)
# =============================================================================
install_packages() {
  local missing=() p cmd
  for p in "${PKGS[@]}"; do
    cmd=$p; [[ $p == openssh ]] && cmd=ssh   # el binario de openssh es ssh
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$p")
  done

  if (( ${#missing[@]} == 0 )); then
    ok "Paquetes ya instalados: ${PKGS[*]}"
    return 0
  fi
  info "Instalando paquetes que faltan: ${missing[*]}"
  run_with_spinner "pkg update" pkg update -y
  for p in "${missing[@]}"; do
    run_with_spinner "Instalando $p" pkg install -y "$p" \
      || die "No se pudo instalar '$p'."
  done
  # Verificación final
  for p in "${PKGS[@]}"; do
    cmd=$p; [[ $p == openssh ]] && cmd=ssh
    command -v "$cmd" >/dev/null 2>&1 || die "El paquete '$p' no quedó instalado."
  done
  ok "Paquetes listos: ${PKGS[*]}"
}

# =============================================================================
#  6. Backup de configuraciones previas
# =============================================================================
backup_configs() {
  BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
  local copied=0
  _bkp() {  # _bkp <ruta>
    [[ -e "$1" ]] || return 0
    mkdir -p "$BACKUP_DIR$(dirname "$1")"
    cp -a "$1" "$BACKUP_DIR$1"
    copied=1
  }
  _bkp "$HOME/.zshrc"
  _bkp "$HOME/.config/fastfetch"
  _bkp "$HOME/.config/htop"
  _bkp "$HOME/.config/yazi"
  _bkp "$HOME/.ssh/config"
  if (( copied )); then
    ok "Backup de tus configs en $BACKUP_DIR"
  else
    rmdir "$BACKUP_DIR" 2>/dev/null || true
    info "No había configs previas — nada que respaldar"
  fi
}

# =============================================================================
#  7. Copiar configs a sus rutas
# =============================================================================
install_configs() {
  local src=$1
  [[ -f "$src/config/zsh/.zshrc" ]]            && cp    "$src/config/zsh/.zshrc" "$HOME/.zshrc"
  mkdir -p "$HOME/.config/fastfetch"
  cp "$src/config/fastfetch/"* "$HOME/.config/fastfetch/" 2>/dev/null || true
  mkdir -p "$HOME/.config/htop" && cp "$src/config/htop/htoprc" "$HOME/.config/htop/htoprc"
  mkdir -p "$HOME/.config/yazi" && cp "$src/config/yazi/"* "$HOME/.config/yazi/"
  mkdir -p "$HOME/.ssh"         && cp "$src/config/ssh/config" "$HOME/.ssh/config"
  chmod 700 "$HOME/.ssh" && chmod 600 "$HOME/.ssh/config"
  ok "Configuraciones copiadas a \$HOME"
}

# =============================================================================
#  Flujo principal
# =============================================================================
main() {
  printf '%s' "$P"
  cat <<'BANNER'

   ╔╦╗┬ ┬  ╔╦╗┌─┐┬─┐┌┬┐┬ ┬─┐ ┬
   ║║║└┬┘───║ ├┤ ├┬┘││││ │┌┴┬┘
   ╩ ╩ ┴   ╩ └─┘┴└─┴ ┴└─┘┴ └─
BANNER
  printf '%s       instalador · %s%s\n\n' "$D" "$REPO" "$N"

  check_environment
  check_internet
  fetch_remote_version

  # Versiones para mostrar/comparar
  local cur
  cur=$(installed_version)
  CUR_DISPLAY="$cur"; [[ $cur != "no instalada" && $cur != v* ]] && CUR_DISPLAY="v$cur"
  TAG_DISPLAY="$TAG"; [[ $TAG != "main" && $TAG != v* ]] && TAG_DISPLAY="v$TAG"

  if [[ $TAG != "main" && "v$cur" == "$TAG_DISPLAY" ]]; then
    ok "Ya tienes la última versión instalada ($TAG_DISPLAY)"
    printf '  %s¿Reinstalar de todas formas? (s/n)%s ' "$B" "$N"
    local ans; read -r ans
    [[ $ans == [sSyY] ]] || { info "Sin cambios. ¡Hasta luego!"; exit 0; }
  fi

  # Descargar y extraer
  TMP_DIR=$(mktemp -d)
  download_with_progress "$DOWNLOAD_URL" "$TMP_DIR/pkg.tar.gz"
  tar -xzf "$TMP_DIR/pkg.tar.gz" -C "$TMP_DIR"
  local SRC
  SRC=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)
  [[ -n "$SRC" && -d "$SRC/config" ]] || die "El paquete descargado no tiene la estructura esperada."

  install_packages
  backup_configs
  install_configs "$SRC"

  # Guardar versión instalada (sin prefijo v)
  mkdir -p "$STATE_DIR"
  if [[ $TAG == main ]]; then
    cat "$SRC/VERSION" > "$VERSION_FILE" 2>/dev/null || echo "main" > "$VERSION_FILE"
  else
    printf '%s\n' "${TAG#v}" > "$VERSION_FILE"
  fi

  # Resumen final
  printf '\n%s╭──────────────────────────────────────────────╮' "$P"
  printf '\n│  %s✔ Instalación completada%s                    %s│' "$G" "$N" "$P"
  printf '\n╰──────────────────────────────────────────────╯%s\n' "$N"
  printf '  %s•%s Versión:    %s\n'   "$P" "$N" "$TAG_DISPLAY"
  printf '  %s•%s Paquetes:   %s\n'   "$P" "$N" "${PKGS[*]}"
  printf '  %s•%s Configs:    ~/.zshrc · fastfetch · htop · yazi · ssh\n' "$P" "$N"
  [[ -n "${BACKUP_DIR:-}" && -d "${BACKUP_DIR:-}" ]] \
    && printf '  %s•%s Backup:     %s\n' "$P" "$N" "$BACKUP_DIR"
  printf '\n  %s➜ Cierra y vuelve a abrir Termux para aplicar todo.%s\n\n' "$BOLD" "$N"
}

main "$@"
