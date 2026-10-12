#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
#  susu — instalador de Termux con un solo comando
#
#    curl -fsSL https://raw.githubusercontent.com/jephersonRD/susu/main/install.sh | bash
#
#  Funciones:
#    · Banner 3D "SUSU" con degradado morado → cian (editable en variables).
#    · Selector de idioma Español/English (recordado en ~/.config/susu/lang).
#    · Menú: 1) Instalar  2) Actualizar  3) Borrar  4) Salir
#    · Descarga con barra de progreso REAL (Content-Length + velocidad).
#    · Backup de configs previas e instalación idempotente de paquetes.
#    · Desinstalación completa dejando Termux por defecto.
#
#  Autor: jephersonRD · Licencia: MIT
# =============================================================================
set -euo pipefail

# =============================================================================
#  CONFIGURACIÓN FÁCIL DE EDITAR
# =============================================================================
REPO="jephersonRD/susu"                                   # user/repo de GitHub
SCRIPT_VERSION="0.0.2"                                   # versión del instalador (fuente única)
API_LATEST="https://api.github.com/repos/${REPO}/releases/latest"
RAW_MAIN="https://codeload.github.com/${REPO}/tar.gz/refs/heads/main"

STATE_DIR="$HOME/.config/susu"                           # estado (lang, version)
LANG_FILE="$STATE_DIR/lang"
VERSION_FILE="$STATE_DIR/version"
BACKUP_ROOT="$HOME/.susu-backup"                         # backups con fecha

PKGS=(zsh htop yazi fastfetch openssh)                   # paquetes que instala susu
BAR_W=20                                                 # ancho de la barra de progreso

# ── Colores ANSI 256 (cámbialos aquí) ────────────────────────────────────────
P=$'\e[38;5;141m'    # lila (color principal)
B=$'\e[38;5;111m'    # azul pastel (acentos)
G=$'\e[38;5;114m'    # verde (éxito)
Y=$'\e[38;5;220m'    # amarillo (avisos)
R=$'\e[38;5;203m'    # rojo (errores)
D=$'\e[2m'           # tenue
BOLD=$'\e[1m'
N=$'\e[0m'           # reset

# ── Degradado del banner (morado → cian), un color por línea ─────────────────
SUSU_GRADIENT=(99 135 141 147 81 51)

# =============================================================================
#  i18n — TODOS los textos del script viven aquí (ES/EN)
#  Uso:  printf "$(t clave)" args...
# =============================================================================
declare -A ES EN

# Español
ES[lang_prompt]="Elige tu idioma / Choose your language"
ES[lang_opts]="  1) English\n  2) Español"
ES[lang_saved]="Idioma guardado: Español"
ES[menu_title]="Menú principal"
ES[menu_installed]="Instalada"
ES[menu_latest]="Disponible"
ES[menu_opt1]="Instalar"
ES[menu_opt2]="Actualizar"
ES[menu_opt3]="Borrar (restaurar Termux)"
ES[menu_opt4]="Salir"
ES[menu_prompt]="Elige una opción [1-4]:"
ES[menu_invalid]="Opción no válida, inténtalo de nuevo."
ES[menu_none]="no instalada"
ES[menu_unknown]="desconocida"
ES[already_installed]="Ya está instalado (v%s). Usa la opción 2 para actualizar."
ES[not_installed]="No está instalado todavía. Usa la opción 1 (Instalar)."
ES[up_to_date]="¡Ya tienes la última versión (v%s)!"
ES[update_found]="Actualización disponible: v%s  →  v%s"
ES[nothing_new]="No hay versiones nuevas publicadas."
ES[uninstall_title]="Borrado completo de la personalización"
ES[uninstall_warn]="Se eliminarán las configs instaladas, el estado de susu y se desinstalarán los paquetes:"
ES[uninstall_shell]="También se restaurará el shell por defecto (bash)."
ES[uninstall_confirm]="Escribe «%s» para confirmar:"
ES[uninstall_aborted]="Cancelado. No se ha tocado nada."
ES[uninstall_offer_backup]="¿Hacer un backup rápido de tus configs antes de borrar? (s/n):"
ES[uninstall_done]="Borrado completado. Termux volverá por defecto al reiniciar."
ES[uninstall_restart]="Reinicia Termux (cierra todas las sesiones) para aplicar los cambios."
ES[uninstall_ssh_note]="Tus claves privadas (~/.ssh/id_*) y known_hosts NO se han tocado."
ES[goodbye]="¡Hasta luego! Gracias por usar susu 💜"
ES[requires_tty]="Este instalador necesita una terminal interactiva (no se pudo leer de /dev/tty)."
ES[hdr_current]="Versión actual"
ES[hdr_new]="Nueva"
ES[hdr_size]="Peso"
ES[downloading]="Descargando"
ES[download_done]="Descarga completada"
ES[extracting]="Extrayendo paquete"
ES[pkg_update]="Actualizando repositorios (pkg update)"
ES[pkg_installing]="Instalando"
ES[pkg_all]="Paquetes ya presentes"
ES[pkg_ready]="Paquetes listos"
ES[backup_done]="Backup de tus configs en"
ES[backup_none]="No había configs previas — nada que respaldar"
ES[configs_done]="Configuraciones copiadas a \$HOME"
ES[version_saved]="Versión instalada guardada"
ES[summary_title]="Instalación completada"
ES[summary_version]="Versión:"
ES[summary_pkgs]="Paquetes:"
ES[summary_configs]="Configs:"
ES[summary_backup]="Backup:"
ES[restart_hint]="Cierra y vuelve a abrir Termux para aplicar todo."
ES[err_termux]="Este instalador solo funciona dentro de Termux (Android)."
ES[err_curl]="Falta 'curl'. Instálalo con: pkg install curl"
ES[err_internet]="Sin conexión a internet o github.com no responde."
ES[err_download]="La descarga falló. Revisa tu conexión e inténtalo de nuevo."
ES[err_pkg]="No se pudo instalar el paquete"
ES[err_structure]="El paquete descargado no tiene la estructura esperada."
ES[err_repo]="No se encontró el repositorio o la release en GitHub."
ES[warn_main]="Aún no hay releases publicados — se usará la rama main."
ES[warn_noasset]="El release no tiene .tar.gz adjunto; se usará el tarball del tag."
ES[confirm_yes]="si"

# English
EN[lang_prompt]="Choose your language / Elige tu idioma"
EN[lang_opts]="  1) English\n  2) Español"
EN[lang_saved]="Language saved: English"
EN[menu_title]="Main menu"
EN[menu_installed]="Installed"
EN[menu_latest]="Available"
EN[menu_opt1]="Install"
EN[menu_opt2]="Update"
EN[menu_opt3]="Uninstall (restore Termux)"
EN[menu_opt4]="Exit"
EN[menu_prompt]="Choose an option [1-4]:"
EN[menu_invalid]="Invalid option, try again."
EN[menu_none]="not installed"
EN[menu_unknown]="unknown"
EN[already_installed]="Already installed (v%s). Use option 2 to update."
EN[not_installed]="Not installed yet. Use option 1 (Install)."
EN[up_to_date]="You already have the latest version (v%s)!"
EN[update_found]="Update available: v%s  →  v%s"
EN[nothing_new]="No new versions published yet."
EN[uninstall_title]="Full uninstall of your customization"
EN[uninstall_warn]="Installed configs and susu state will be removed, and these packages will be uninstalled:"
EN[uninstall_shell]="The default shell (bash) will be restored too."
EN[uninstall_confirm]="Type «%s» to confirm:"
EN[uninstall_aborted]="Aborted. Nothing was changed."
EN[uninstall_offer_backup]="Make a quick backup of your configs before deleting? (y/n):"
EN[uninstall_done]="Uninstall complete. Termux will be back to default after restarting."
EN[uninstall_restart]="Restart Termux (close every session) to apply the changes."
EN[uninstall_ssh_note]="Your private keys (~/.ssh/id_*) and known_hosts were NOT touched."
EN[goodbye]="Goodbye! Thanks for using susu 💜"
EN[requires_tty]="This installer needs an interactive terminal (could not read from /dev/tty)."
EN[hdr_current]="Current version"
EN[hdr_new]="New"
EN[hdr_size]="Size"
EN[downloading]="Downloading"
EN[download_done]="Download complete"
EN[extracting]="Extracting package"
EN[pkg_update]="Updating repositories (pkg update)"
EN[pkg_installing]="Installing"
EN[pkg_all]="Packages already present"
EN[pkg_ready]="Packages ready"
EN[backup_done]="Backup of your configs at"
EN[backup_none]="No previous configs — nothing to back up"
EN[configs_done]="Configs copied to \$HOME"
EN[version_saved]="Installed version saved"
EN[summary_title]="Installation complete"
EN[summary_version]="Version:"
EN[summary_pkgs]="Packages:"
EN[summary_configs]="Configs:"
EN[summary_backup]="Backup:"
EN[restart_hint]="Close and reopen Termux to apply everything."
EN[err_termux]="This installer only works inside Termux (Android)."
EN[err_curl]="'curl' is missing. Install it with: pkg install curl"
EN[err_internet]="No internet connection or github.com is unreachable."
EN[err_download]="Download failed. Check your connection and try again."
EN[err_pkg]="Could not install package"
EN[err_structure]="The downloaded package has an unexpected structure."
EN[err_repo]="Repository or release not found on GitHub."
EN[warn_main]="No releases published yet — falling back to the main branch."
EN[warn_noasset]="Release has no .tar.gz asset; using the tag tarball."
EN[confirm_yes]="yes"

LANG_CODE="es"   # se sobrescribe en select_language

# t <clave> → imprime el texto en el idioma activo (fallback a ES)
t() {
  local key="$1"
  if [[ "$LANG_CODE" == "en" ]]; then
    printf '%s' "${EN[$key]:-${ES[$key]:-$key}}"
  else
    printf '%s' "${ES[$key]:-$key}"
  fi
}
# tp <clave> args... → texto + printf (para mensajes con %s)
tp() { local key="$1"; shift; printf "$(t "$key")" "$@"; }

ES[spinner_failed]="falló"
EN[spinner_failed]="failed"

# =============================================================================
#  Utilidades de salida y entrada
# =============================================================================
ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$1"; }
info() { printf '  %s➜%s %s\n' "$B" "$N" "$1"; }
warn() { printf '  %s⚠%s %s\n' "$Y" "$N" "$1"; }
die()  { printf '  %s✘%s %s\n' "$R" "$N" "$1" >&2; exit 1; }

hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }

# ask <var> <prompt> — lee UNA línea desde /dev/tty (funciona con curl | bash)
ask() {
  local __var="$1" __prompt="${2:-}"
  printf '%s ' "$__prompt"
  [[ -r /dev/tty ]] || return 1
  IFS= read -r "$__var" < /dev/tty || return 1
  return 0
}

# Traps: restaurar cursor y limpiar temporales SIEMPRE
TMP_DIR=""
on_exit() {
  show_cursor
  [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
  return 0
}
on_err() { show_cursor; printf '\n  %s✘ %s (line %s)%s\n' "$R" "$(t err_generic)" "$1" "$N" >&2; }
ES[err_generic]="Error inesperado en la línea"; EN[err_generic]="Unexpected error at line"
trap on_exit EXIT
trap 'on_err $LINENO' ERR
trap 'exit 130' INT TERM

# =============================================================================
#  Comprobaciones del entorno
# =============================================================================
check_environment() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]] || die "$(t err_termux)"
  command -v pkg  >/dev/null 2>&1 || die "$(t err_termux)"
  command -v curl >/dev/null 2>&1 || die "$(t err_curl)"
}

check_internet() {
  curl -fsI -m 10 https://github.com >/dev/null 2>&1
}

# =============================================================================
#  Banner 3D con degradado (se limpia la pantalla antes)
# =============================================================================
print_banner() {
  clear
  printf '\n'
  local -a art=(
    '███████╗██╗   ██╗███████╗██╗   ██╗'
    '██╔════╝██║   ██║██╔════╝██║   ██║'
    '███████╗██║   ██║███████╗██║   ██║'
    '╚════██║██║   ██║╚════██║██║   ██║'
    '███████║╚██████╔╝███████║╚██████╔╝'
    '╚══════╝ ╚═════╝ ╚══════╝ ╚═════╝'
  )
  local cols="${COLUMNS:-80}"
  command -v tput >/dev/null 2>&1 && cols=$(tput cols 2>/dev/null || echo "$cols")
  if (( cols >= 40 )); then
    local i=0 line
    for line in "${art[@]}"; do
      printf '\e[38;5;%sm%s%s\n' "${SUSU_GRADIENT[i]:-141}" "$line" "$N"
      (( i++ )) || true
    done
    printf '      %sMy Termux Config · v%s%s\n\n' "$D" "$SCRIPT_VERSION" "$N"
  else
    # Terminal muy estrecha: banner compacto (mínimo 40 columnas recomendado)
    printf '  %s%sSUSU%s %s· My Termux Config · v%s%s\n\n' \
      "$BOLD" "$P" "$N" "$D" "$SCRIPT_VERSION" "$N"
  fi
}

# =============================================================================
#  Selector de idioma
# =============================================================================
select_language() {
  # 1) --lang tiene prioridad y se persiste
  if [[ -n "${CLI_LANG:-}" ]]; then
    LANG_CODE="$CLI_LANG"
    mkdir -p "$STATE_DIR"; printf '%s\n' "$LANG_CODE" > "$LANG_FILE"
    return 0
  fi
  # 2) idioma guardado de ejecuciones anteriores
  if [[ -f "$LANG_FILE" ]]; then
    LANG_CODE=$(cat "$LANG_FILE" 2>/dev/null || echo es)
    [[ "$LANG_CODE" == "en" || "$LANG_CODE" == "es" ]] || LANG_CODE=es
    return 0
  fi
  # 3) primera vez: preguntar (bilingüe, sin traducir)
  printf '  %s%s%s\n' "$BOLD" "${ES[lang_prompt]}" "$N"
  printf '%b\n' "${ES[lang_opts]}"
  local choice=""
  if ask choice "  →" ; then
    case "$choice" in
      1) LANG_CODE="en" ;;
      *) LANG_CODE="es" ;;
    esac
  else
    LANG_CODE="es"   # sin tty: español por defecto
  fi
  mkdir -p "$STATE_DIR"; printf '%s\n' "$LANG_CODE" > "$LANG_FILE"
  ok "$(t lang_saved)"
}

# =============================================================================
#  Versiones: instalada, remota y comparación SemVer real
# =============================================================================
installed_version() {
  [[ -f "$VERSION_FILE" ]] && cat "$VERSION_FILE" || printf 'no instalada'
}

# semver_gt A B → verdadero si A > B (comparación numérica por segmentos)
semver_gt() {
  local a="${1#v}" b="${2#v}"
  local -a A B
  IFS='.' read -r -a A <<< "$a"
  IFS='.' read -r -a B <<< "$b"
  local i x y
  for i in 0 1 2; do
    x="${A[i]:-0}"; y="${B[i]:-0}"
    x="${x//[^0-9]/}"; y="${y//[^0-9]/}"   # por si traen sufijos
    x="${x:-0}"; y="${y:-0}"
    (( 10#$x > 10#$y )) && return 0
    (( 10#$x < 10#$y )) && return 1
  done
  return 1   # iguales → no es mayor
}

# Consulta la última release (API de GitHub, sin jq) → TAG y DOWNLOAD_URL
fetch_remote_version() {
  local json=""
  json=$(curl -fsSL -m 20 "$API_LATEST" 2>/dev/null) || json=""
  TAG=$(printf '%s' "$json" | grep -m1 '"tag_name"' \
      | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)
  if [[ -z "$TAG" ]]; then
    warn "$(t warn_main)"
    TAG="main"
    DOWNLOAD_URL="$RAW_MAIN"
  else
    local asset
    asset=$(printf '%s' "$json" | grep '"browser_download_url"' \
        | grep '\.tar\.gz' | head -n1 \
        | sed -E 's/.*"(https:[^"]+\.tar\.gz)".*/\1/' || true)
    if [[ -n "$asset" ]]; then
      DOWNLOAD_URL="$asset"
    else
      DOWNLOAD_URL="https://codeload.github.com/${REPO}/tar.gz/refs/tags/${TAG}"
      warn "$(t warn_noasset)"
    fi
  fi
}

# =============================================================================
#  Descarga con barra de progreso REAL (Content-Length + velocidad)
# =============================================================================
fmt_size() { awk -v b="${1:-0}" 'BEGIN {
  if (b >= 1048576) printf "%.1f MB", b / 1048576
  else              printf "%.1f KB", b / 1024 }'; }

remote_size() {
  curl -fsIL -m 15 "$1" 2>/dev/null \
    | grep -i '^content-length:' | tail -n1 \
    | tr -d '\r' | awk '{print $2}' || true
}

draw_bar() {   # <descargados> <total> <velocidad B/s>
  local size=$1 total=$2 speed=$3
  local pct=0 filled=0 i bar=""
  if (( total > 0 )); then
    pct=$(( size * 100 / total )); (( pct > 100 )) && pct=100
    filled=$(( pct * BAR_W / 100 ))
  fi
  for (( i = 0; i < BAR_W; i++ )); do
    (( i < filled )) && bar+="█" || bar+="░"
  done
  printf '\r  %s[%s]%s %3d%%  %s/%s  %s/s   ' \
    "$P" "$bar" "$N" "$pct" \
    "$(fmt_size "$size")" "$(fmt_size "$total")" "$(fmt_size "$speed")"
}

download_with_progress() {   # <url> <destino>
  local url="$1" out="$2" total
  total=$(remote_size "$url"); total=${total:-0}

  printf '\n  %s⬇ susu%s\n' "$BOLD$P" "$N"
  printf '  %s: %s  →  %s: %s\n' "$(t hdr_current)" "$CUR_DISPLAY" "$(t hdr_new)" "$TAG_DISPLAY"
  if (( total > 0 )); then
    printf '  %s: %s\n\n' "$(t hdr_size)" "$(fmt_size "$total")"
  else
    printf '  %s: %s%s%s\n\n' "$(t hdr_size)" "$D" "$(t menu_unknown)" "$N"
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
    tar -tzf "$out" &>/dev/null || die "$(t err_repo)"
    (( total > 0 )) || total=$size
    draw_bar "$size" "$total" "$speed"; printf '\n\n'
    ok "$(t download_done)"
  else
    show_cursor
    die "$(t err_download)"
  fi
}

# =============================================================================
#  Spinner con el mismo estilo, para pasos largos (pkg...)
# =============================================================================
run_with_spinner() {   # <mensaje> cmd args...
  local msg="$1"; shift
  hide_cursor
  "$@" &>/dev/null & local pid=$!
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏) i=1
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r  %s%s%s %s' "$P" "${frames[i]}" "$N" "$msg"
    (( i = i % 10 + 1 )); sleep 0.1
  done
  show_cursor
  if wait "$pid"; then
    printf '\r  %s✔%s %s   \n' "$G" "$N" "$msg"
  else
    printf '\r  %s✘%s %s %s(%s)%s\n' "$R" "$N" "$msg" "$D" "$(t spinner_failed)" "$N"
    return 1
  fi
}

# =============================================================================
#  Paquetes (solo los que falten — idempotente)
# =============================================================================
install_packages() {
  local missing=() p cmd
  for p in "${PKGS[@]}"; do
    cmd="$p"; [[ "$p" == openssh ]] && cmd=ssh
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$p")
  done
  if (( ${#missing[@]} == 0 )); then
    ok "$(t pkg_all): ${PKGS[*]}"
    return 0
  fi
  info "$(t pkg_installing): ${missing[*]}"
  run_with_spinner "$(t pkg_update)" pkg update -y
  for p in "${missing[@]}"; do
    run_with_spinner "$(t pkg_installing) $p" pkg install -y "$p" \
      || die "$(t err_pkg) '$p'."
  done
  for p in "${PKGS[@]}"; do
    cmd="$p"; [[ "$p" == openssh ]] && cmd=ssh
    command -v "$cmd" >/dev/null 2>&1 || die "$(t err_pkg) '$p'."
  done
  ok "$(t pkg_ready): ${PKGS[*]}"
}

# =============================================================================
#  Backup de configs previas
# =============================================================================
BACKUP_DIR=""
_bkp() {   # _bkp <ruta>
  [[ -e "$1" ]] || return 0
  mkdir -p "$BACKUP_DIR$(dirname "$1")"
  cp -a "$1" "$BACKUP_DIR$1"
}

backup_configs() {
  BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
  local before=0
  [[ -e "$HOME/.zshrc" || -e "$HOME/.config/fastfetch" || -e "$HOME/.config/htop" \
     || -e "$HOME/.config/yazi" || -e "$HOME/.ssh/config" ]] && before=1
  _bkp "$HOME/.zshrc"
  _bkp "$HOME/.config/fastfetch"
  _bkp "$HOME/.config/htop"
  _bkp "$HOME/.config/yazi"
  _bkp "$HOME/.ssh/config"
  if (( before )); then
    ok "$(t backup_done) $BACKUP_DIR"
  else
    rmdir "$BACKUP_DIR" 2>/dev/null || true
    info "$(t backup_none)"
  fi
}

# =============================================================================
#  Copiar configs a sus rutas definitivas
# =============================================================================
install_configs() {   # <dir origen> (contiene config/)
  local src="$1"
  [[ -f "$src/config/zsh/.zshrc" ]] && cp "$src/config/zsh/.zshrc" "$HOME/.zshrc"
  mkdir -p "$HOME/.config/fastfetch"
  cp "$src/config/fastfetch/"* "$HOME/.config/fastfetch/" 2>/dev/null || true
  mkdir -p "$HOME/.config/htop" && cp "$src/config/htop/htoprc" "$HOME/.config/htop/htoprc"
  mkdir -p "$HOME/.config/yazi" && cp "$src/config/yazi/"* "$HOME/.config/yazi/"
  mkdir -p "$HOME/.ssh"         && cp "$src/config/ssh/config" "$HOME/.ssh/config"
  chmod 700 "$HOME/.ssh" && chmod 600 "$HOME/.ssh/config"
  ok "$(t configs_done)"
}

# =============================================================================
#  Flujo compartido: descargar + aplicar (lo usan Instalar y Actualizar)
# =============================================================================
do_download_and_apply() {
  check_internet || die "$(t err_internet)"
  fetch_remote_version

  local cur; cur=$(installed_version)
  CUR_DISPLAY="$cur"
  [[ "$cur" != "no instalada" && "$cur" != v* ]] && CUR_DISPLAY="v$cur"
  TAG_DISPLAY="$TAG"
  [[ "$TAG" != "main" && "$TAG" != v* ]] && TAG_DISPLAY="v$TAG"

  TMP_DIR=$(mktemp -d)
  download_with_progress "$DOWNLOAD_URL" "$TMP_DIR/pkg.tar.gz"
  run_with_spinner "$(t extracting)" tar -xzf "$TMP_DIR/pkg.tar.gz" -C "$TMP_DIR"
  local SRC
  SRC=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)
  [[ -n "$SRC" && -d "$SRC/config" ]] || die "$(t err_structure)"

  install_packages
  backup_configs
  install_configs "$SRC"

  mkdir -p "$STATE_DIR"
  if [[ "$TAG" == "main" ]]; then
    cat "$SRC/VERSION" > "$VERSION_FILE" 2>/dev/null || echo "main" > "$VERSION_FILE"
  else
    printf '%s\n' "${TAG#v}" > "$VERSION_FILE"
  fi
  ok "$(t version_saved): $(installed_version)"

  # Resumen final
  printf '\n%s╭──────────────────────────────────────────────╮' "$P"
  printf '\n│  %s✔ %s%s' "$G" "$(t summary_title)" "$N"
  printf '\n╰──────────────────────────────────────────────╯%s\n' "$N"
  printf '  %s•%s %s %s\n' "$P" "$N" "$(t summary_version)" "$TAG_DISPLAY"
  printf '  %s•%s %s %s\n' "$P" "$N" "$(t summary_pkgs)" "${PKGS[*]}"
  printf '  %s•%s %s ~/.zshrc · fastfetch · htop · yazi · ssh\n' "$P" "$N" "$(t summary_configs)"
  [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]] \
    && printf '  %s•%s %s %s\n' "$P" "$N" "$(t summary_backup)" "$BACKUP_DIR"
  printf '\n  %s➜ %s%s\n\n' "$BOLD" "$(t restart_hint)" "$N"
}

# =============================================================================
#  Opción 1 — Instalar
# =============================================================================
action_install() {
  local cur; cur=$(installed_version)
  if [[ "$cur" != "no instalada" ]]; then
    warn "$(tp already_installed "$cur")"
    return 0
  fi
  do_download_and_apply
}

# =============================================================================
#  Opción 2 — Actualizar (solo si hay versión más nueva, SemVer real)
# =============================================================================
action_update() {
  local cur; cur=$(installed_version)
  if [[ "$cur" == "no instalada" ]]; then
    warn "$(t not_installed)"
    return 0
  fi
  check_internet || die "$(t err_internet)"
  fetch_remote_version
  if [[ "$TAG" == "main" ]]; then
    info "$(t nothing_new)"
    return 0
  fi
  local remote="${TAG#v}"
  if semver_gt "$remote" "$cur"; then
    tp update_found "$cur" "$remote"; printf '\n'
    do_download_and_apply
  else
    ok "$(tp up_to_date "$cur")"
  fi
}

# =============================================================================
#  Opción 3 — Borrar: deja Termux por defecto
# =============================================================================
action_uninstall() {
  printf '\n  %s%s%s\n' "$BOLD" "$(t uninstall_title)" "$N"
  printf '  %s\n' "$(t uninstall_warn)"
  printf '  %s· %s%s\n' "$P" "${PKGS[*]}" "$N"
  printf '  %s\n\n' "$(t uninstall_shell)"

  local word; word="$(t confirm_yes)"
  local ans=""
  if ! ask ans "  $(tp uninstall_confirm "$word")"; then
    die "$(t requires_tty)"
  fi
  [[ "$ans" == "$word" ]] || { info "$(t uninstall_aborted)"; return 0; }

  # Backup rápido opcional (NO restaura solo: es una red de seguridad)
  local b=""
  if ask b "  $(t uninstall_offer_backup)"; then
    case "$b" in
      s|S|y|Y)
        BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
        _bkp "$HOME/.zshrc"; _bkp "$HOME/.config/fastfetch"; _bkp "$HOME/.config/htop"
        _bkp "$HOME/.config/yazi"; _bkp "$HOME/.ssh/config"
        ok "$(t backup_done) $BACKUP_DIR"
        ;;
    esac
  fi

  # 1) Borrar SOLO la configuración instalada por susu (nunca claves privadas)
  rm -f  "$HOME/.zshrc"
  rm -rf "$HOME/.config/fastfetch" "$HOME/.config/htop" "$HOME/.config/yazi"
  rm -f  "$HOME/.ssh/config"          # solo el config, NO ~/.ssh completo
  rm -rf "$STATE_DIR"
  ok "~/.zshrc · ~/.config/{fastfetch,htop,yazi} · ~/.ssh/config ✘"

  # 2) Restaurar shell por defecto
  if command -v chsh >/dev/null 2>&1; then
    chsh -s bash 2>/dev/null || true
    ok "chsh -s bash"
  fi

  # 3) Desinstalar paquetes que instaló susu
  run_with_spinner "pkg uninstall" pkg uninstall -y "${PKGS[@]}" || true

  printf '\n  %s✔ %s%s\n' "$G" "$(t uninstall_done)" "$N"
  printf '  %s%s%s\n' "$D" "$(t uninstall_ssh_note)" "$N"
  printf '  %s➜ %s%s\n\n' "$BOLD" "$(t uninstall_restart)" "$N"
}

# =============================================================================
#  Menú principal
# =============================================================================
print_menu() {
  local cur latest
  cur=$(installed_version)
  [[ "$cur" != "no instalada" && "$cur" != v* ]] && cur="v$cur"
  if [[ -n "${TAG:-}" && "$TAG" != "main" ]]; then
    latest="$TAG"; [[ "$latest" != v* ]] && latest="v$latest"
  else
    latest="$(t menu_unknown)"
  fi
  local dashes; dashes=$(printf '─%.0s' {1..45})
  local full;   full=$(printf '─%.0s' {1..52})
  printf '%s╭─ %ssusu%s %s╮%s\n' "$P" "$BOLD" "$N$P" "$dashes" "$N"
  printf '%s│%s  %s: %s%s%s  %s: %s%s%s\n' \
    "$P" "$N" "$(t menu_installed)" "$B" "$cur" "$N" \
    "$(t menu_latest)" "$B" "$latest" "$N"
  printf '%s╰%s╯%s\n' "$P" "$full" "$N"
  printf '  %s1)%s %s\n' "$B" "$N" "$(t menu_opt1)"
  printf '  %s2)%s %s\n' "$B" "$N" "$(t menu_opt2)"
  printf '  %s3)%s %s\n' "$B" "$N" "$(t menu_opt3)"
  printf '  %s4)%s %s\n\n' "$B" "$N" "$(t menu_opt4)"
}

menu_loop() {
  # Última versión conocida para el menú (solo si hay internet)
  if check_internet; then fetch_remote_version &>/dev/null || true; fi

  while true; do
    print_menu
    local opt="" 
    if ! ask opt "  $(t menu_prompt)"; then
      printf '\n'
      die "$(t requires_tty)"
    fi
    case "$opt" in
      1) action_install ;;
      2) action_update ;;
      3) action_uninstall ;;
      4) info "$(t goodbye)"; exit 0 ;;
      *) warn "$(t menu_invalid)"; printf '\n' ;;
    esac
    printf '\n'
  done
}

# =============================================================================
#  Argumentos de línea de comandos: --lang es|en
# =============================================================================
parse_args() {
  CLI_LANG=""
  while (( $# )); do
    case "$1" in
      --lang=*) CLI_LANG="${1#--lang=}" ;;
      --lang)   shift || true; CLI_LANG="${1:-}" ;;
      -h|--help)
        printf 'Uso: install.sh [--lang es|en]\n'
        exit 0 ;;
      *) ;;   # ignorar desconocidos
    esac
    shift || true
  done
  case "${CLI_LANG:-}" in
    es|en) ;;
    *) CLI_LANG="" ;;
  esac
}

# =============================================================================
#  main
# =============================================================================
main() {
  parse_args "$@"
  check_environment          # silencioso salvo error

  print_banner               # clear + banner 3D con degradado
  select_language            # 1er paso: idioma (o --lang / idioma guardado)

  menu_loop
}

main "$@"
