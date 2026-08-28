# 15-theme.zsh — follow macOS light/dark appearance
# ---------------------------------------------------------------
# Loads BEFORE the prompt so $_THEME_MODE exists when p10k initializes.
#
# How the detection stays cheap: asking macOS for the current appearance
# means launching the `defaults` program, which costs ~15ms. Doing that on
# every prompt would be felt. Instead we check the modification timestamp
# of the preferences file that stores the setting — that's a syscall with
# no process launch, effectively free — and only ask `defaults` when the
# timestamp actually moved. A 30-second fallback covers the case where
# macOS batches the write and the timestamp lags.
#
# Manual override:  theme dark | theme light | theme auto
# ---------------------------------------------------------------

zmodload zsh/stat 2>/dev/null
zmodload zsh/datetime 2>/dev/null
autoload -Uz add-zsh-hook

typeset -g _THEME_PLIST="$HOME/Library/Preferences/.GlobalPreferences.plist"
typeset -g _THEME_MODE=""          # "dark" | "light" — read by ~/.p10k.zsh
typeset -g _THEME_PIN=""           # non-empty = manual override, stop auto-detecting
typeset -g _THEME_MTIME=0
typeset -g _THEME_LAST_POLL=0

# --- Ask macOS which appearance is active ---
_theme_query() {
  [[ "$(command defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark* ]] \
    && echo dark || echo light
}

# --- Apply a mode to everything that isn't the prompt ---
# (the prompt itself reads $_THEME_MODE from ~/.p10k.zsh)
_theme_apply_tools() {
  local mode="$1"

  if [[ $mode == dark ]]; then
    # bat: syntax highlighting for `cat`, and delta inherits this
    export BAT_THEME="OneHalfDark"
    # delta: its own UI chrome (line numbers, +/- backgrounds)
    export GIT_CONFIG_PARAMETERS="'delta.dark=true'"
    # the grey ghost-text of autosuggestions
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
    local fzf_colors="
      --color=fg:-1,bg:-1,hl:#89b4fa
      --color=fg+:#cdd6f4,bg+:#313244,hl+:#89b4fa
      --color=info:#94e2d5,prompt:#cba6f7,pointer:#f38ba8
      --color=marker:#a6e3a1,spinner:#f5c2e7,header:#6c7086
      --color=border:#45475a"
  else
    export BAT_THEME="OneHalfLight"
    export GIT_CONFIG_PARAMETERS="'delta.light=true'"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=250'
    local fzf_colors="
      --color=fg:-1,bg:-1,hl:#1e66f5
      --color=fg+:#4c4f69,bg+:#ccd0da,hl+:#1e66f5
      --color=info:#179299,prompt:#8839ef,pointer:#d20f39
      --color=marker:#40a02b,spinner:#ea76cb,header:#8c8fa1
      --color=border:#bcc0cc"
  fi

  export FZF_DEFAULT_OPTS="
    --height=60% --layout=reverse --border=rounded --info=inline
    --prompt='  ' --pointer='▶' --marker='✓'${fzf_colors}"

  # Re-apply the suggestion color to the widget if it's already running
  (( $+functions[_zsh_autosuggest_bind_widgets] )) && \
    typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
}

# --- Switch modes, including reloading the prompt's palette ---
_theme_set() {
  local mode="$1"
  [[ $mode == $_THEME_MODE ]] && return
  typeset -g _THEME_MODE="$mode"
  _theme_apply_tools "$mode"

  # Re-source the prompt config so its light/dark branch runs again.
  # `p10k reload` alone is NOT enough: it re-reads POWERLEVEL9K_* variables
  # already in memory, but never re-reads the file that sets them.
  # ~/.p10k.zsh calls `p10k reload` itself on its way out.
  local cfg="${POWERLEVEL9K_CONFIG_FILE:-$HOME/.p10k.zsh}"
  [[ -r $cfg ]] && (( $+functions[p10k] )) && source "$cfg"
}

# --- The per-prompt check (cheap path first) ---
_theme_sync() {
  [[ -n $_THEME_PIN ]] && return

  local -a st
  local changed=0

  # Free path: has the preferences file been touched?
  if zstat -A st +mtime "$_THEME_PLIST" 2>/dev/null; then
    if [[ $st[1] != $_THEME_MTIME ]]; then
      _THEME_MTIME=$st[1]
      changed=1
    fi
  fi

  # Fallback path: macOS may batch the preferences write, so the timestamp
  # can lag the actual setting. Poll directly at most once every 5 seconds.
  # Measured cost of the poll: 15ms, well under the ~100ms a human notices,
  # and it only happens on a prompt draw at least 5s after the last one.
  if (( ! changed )); then
    (( EPOCHSECONDS - _THEME_LAST_POLL < 5 )) && return
  fi
  _THEME_LAST_POLL=$EPOCHSECONDS

  _theme_set "$(_theme_query)"
}

# --- Manual control ---
theme() {
  case "$1" in
    dark|light)
      _THEME_PIN="$1"
      _theme_set "$1"
      echo "theme pinned to $1 (run 'theme auto' to follow macOS again)" ;;
    auto)
      _THEME_PIN=""
      _THEME_MTIME=0; _THEME_LAST_POLL=0
      _theme_sync
      echo "theme following macOS — currently $_THEME_MODE" ;;
    ""|status)
      echo "mode:   $_THEME_MODE"
      echo "source: ${_THEME_PIN:+pinned manually}${_THEME_PIN:-following macOS}" ;;
    *)
      echo "usage: theme [dark|light|auto|status]"; return 1 ;;
  esac
}

# --- Initialize before the first prompt is drawn ---
_THEME_MODE="$(_theme_query)"
_theme_apply_tools "$_THEME_MODE"
zstat -A _st +mtime "$_THEME_PLIST" 2>/dev/null && _THEME_MTIME=$_st[1]
unset _st
_THEME_LAST_POLL=$EPOCHSECONDS

add-zsh-hook precmd _theme_sync
