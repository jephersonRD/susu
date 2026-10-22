# =============================================================================
# ~/.zshrc — Termux · tema morado/azul pastel
# =============================================================================

# ── Solo shells interactivos (nunca en scripts ni zsh -c) ────────────────────
[[ -o interactive && -t 1 ]] || return 0

export LANG="${LANG:-en_US.UTF-8}"

# Suprime el mensaje de login por si hay otros motd activos
[[ -f ~/.hushlogin ]] || touch ~/.hushlogin

# ── Historial amplio ─────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
zmodload zsh/datetime 2>/dev/null   # para $EPOCHSECONDS (chequeo de updates)

# ── Autocompletado (usa caché: compinit -C = arranque rápido) ────────────────
ZSH_PLUGIN_DIR=~/.local/share/zsh/plugins
fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive

# ── fzf ──────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline
  --color=bg+:#2a2640,hl:#bb9af7,hl+:#bb9af7,pointer:#7aa2f7,prompt:#c0caf5'
[[ -f "$PREFIX/share/fzf/key-bindings.zsh" ]] && source "$PREFIX/share/fzf/key-bindings.zsh"
[[ -f "$PREFIX/share/fzf/completion.zsh"   ]] && source "$PREFIX/share/fzf/completion.zsh"

# ── Plugins (clonados por install.sh) ────────────────────────────────────────
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=243'
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
[[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
  && source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
# syntax-highlighting SIEMPRE al final de los plugins:
[[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
  && source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ── zoxide (cd inteligente: z <dir>) ─────────────────────────────────────────
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# ── Aliases ──────────────────────────────────────────────────────────────────
# Iconos solo si hay fuente Nerd Font instalada (susu la copia en ~/.termux)
if [[ -f ~/.termux/font.ttf ]]; then EZA_ICONS=(--icons); else EZA_ICONS=(); fi
alias ll="eza -la ${EZA_ICONS[*]} --group-directories-first"
alias ls="eza ${EZA_ICONS[*]} --group-directories-first"
alias lt="eza --tree ${EZA_ICONS[*]} --level=2"
alias cat='bat --style=plain --paging=never'
alias y='yazi'
alias top='htop'
alias fetch='fastfetch'
alias c='clear'
alias ..='cd ..' ...='cd ../..'

# yazi: cambiar al directorio visitado al salir (usa: yy)
function yy() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ── Prompt: Starship ─────────────────────────────────────────────────────────
(( $+commands[starship] )) && eval "$(starship init zsh)"

# =============================================================================
#  SALUDO DE BIENVENIDA (mensaje aleatorio con efecto máquina de escribir)
#  ➜ Edita los mensajes en el array TERMUX_GREETINGS
# =============================================================================
TERMUX_GREETINGS=(
  "Hola, ${USER:-jefe}, ¡bienvenido!"
  "¡Saludos, ${USER:-jefe}! ¿Cómo estás?"
  "¡Eyyy! Qué bueno verte por aquí"
  "¡Hola, máquina! Bienvenido, ponte cómodo"
  "¡Wassup, jefe! ¿Todo bien por ahí?"
  "¡Buenas! Un gusto tenerte por aquí"
)
TERMUX_GREETING_DELAY=0.03   # segundos por carácter

_termux_greet() {
  local msg="${TERMUX_GREETINGS[RANDOM % ${#TERMUX_GREETINGS} + 1]}"
  # degradado lila → azul pastel (ANSI 256)
  local grad=(141 147 183 153 111 110)
  local n=${#msg} i idx
  printf '\e[?25l'   # oculta el cursor durante la animación
  for (( i = 1; i <= n; i++ )); do
    idx=$(( (i - 1) * ${#grad} / n + 1 ))
    printf '\e[1;38;5;%sm%s\e[0m' "${grad[idx]}" "${msg[i]}"
    sleep "$TERMUX_GREETING_DELAY"
  done
  # cursor "bloque" parpadeante al final
  repeat 3; do
    printf ' \e[1;38;5;183m▌\e[0m'; sleep 0.28
    printf '\b\b  \b\b';          sleep 0.15
  done
  printf '\e[?25h\n'   # restaura cursor + salto de línea
}

# =============================================================================
#  AVISO DE ACTUALIZACIÓN CADA 24 H
#  ➜ Cambia TERMUX_UPDATE_INTERVAL (segundos); 86400 = 24 h
# =============================================================================
TERMUX_UPDATE_INTERVAL=86400
TERMUX_UPDATE_STAMP=~/.cache/termux-update-check

_termux_spinner() {   # _termux_spinner "mensaje" cmd args...
  local msg="$1"; shift
  "$@" &>/dev/null & local pid=$!
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏) i=1
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r  \e[38;5;141m%s\e[0m %s' "${frames[i]}" "$msg"
    (( i = i % ${#frames} + 1 )); sleep 0.1
  done
  if wait "$pid"; then
    printf '\r  \e[38;5;82m✔\e[0m %s \e[2m(listo)\e[0m   \n' "$msg"
  else
    printf '\r  \e[38;5;203m✘\e[0m %s \e[2m(falló)\e[0m   \n' "$msg"; return 1
  fi
}

_termux_update_check() {
  local now=${EPOCHSECONDS:-$(date +%s)} last=0 ans
  [[ -f "$TERMUX_UPDATE_STAMP" ]] && read -r last < "$TERMUX_UPDATE_STAMP"
  (( now - last < TERMUX_UPDATE_INTERVAL )) && return 0   # aún no toca
  printf '\n\e[38;5;141m╭────────────────────────────────────────────╮'
  printf '\n│\e[0m  \e[1;38;5;183m⬆  Hay actualizaciones por comprobar\e[0m   \e[38;5;141m│'
  printf '\n╰────────────────────────────────────────────╯\e[0m\n'
  printf '  \e[1;38;5;111m¿Quieres actualizar Termux? (s/n)\e[0m '
  read -rk1 ans; printf '\n\n'
  mkdir -p "${TERMUX_UPDATE_STAMP:h}"
  echo "$now" >| "$TERMUX_UPDATE_STAMP"   # pase lo que pase, no repetir en 24 h
  if [[ "$ans" == [sSyY] ]]; then
    _termux_spinner "pkg update"  pkg update  -y \
      && _termux_spinner "pkg upgrade" pkg upgrade -y \
      && printf '  \e[1;38;5;82m✔ Termux actualizado\e[0m\n'
  else
    printf '  \e[2mDe acuerdo, te vuelvo a preguntar en 24 h.\e[0m\n'
  fi
}

# ── Arranque: saludo → fastfetch → chequeo de updates ────────────────────────
_termux_greet
(( $+commands[fastfetch] )) && fastfetch
_termux_update_check
