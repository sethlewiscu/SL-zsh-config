# 18-terminal.zsh — new tabs and splits start in the current directory
# ---------------------------------------------------------------
# Two independent pieces:
#
#   1. Report the directory to the terminal (OSC 7). Good hygiene, and
#      what every other terminal uses, but iTerm2 only acts on it if its
#      profile is set to "Reuse previous session's directory".
#
#   2. Do it in the shell instead, so no iTerm2 setting is required.
#      iTerm2 hands every shell an ITERM_SESSION_ID that looks like
#      "w0t1p0:UUID" — window 0, tab 1, pane 0. Each shell records its
#      directory per window; a shell that starts as a *new tab or split*
#      (tab or pane index above zero) and lands in $HOME moves itself to
#      whatever that window last recorded.
#
# Piece 2 does the real work. It self-disables if the iTerm2 profile
# setting is ever turned on, because then the shell never starts in
# $HOME and the restore condition is never met.
# ---------------------------------------------------------------

autoload -Uz add-zsh-hook

typeset -g _CWD_STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/last-dir"
[[ -d "$_CWD_STATE_DIR" ]] || command mkdir -p "$_CWD_STATE_DIR" 2>/dev/null

# --- Split "w0t1p0:UUID" into window / tab / pane -----------------
# Sets _CWD_WIN, _CWD_TAB, _CWD_PANE. Returns non-zero when not in iTerm2.
_cwd_parse_session() {
  emulate -L zsh
  local id="${ITERM_SESSION_ID%%:*}" rest
  [[ "$id" == w*t*p* ]] || return 1
  _CWD_WIN="${${id%%t*}#w}"
  rest="${id#*t}"
  _CWD_TAB="${rest%%p*}"
  _CWD_PANE="${rest#*p}"
  [[ "$_CWD_WIN" == <-> && "$_CWD_TAB" == <-> && "$_CWD_PANE" == <-> ]]
}

# --- 1. Report the directory to the terminal (OSC 7) --------------
# "OSC" = Operating System Command: an escape sequence that is a message
# to the terminal program, not text for you to read. Terminal.app,
# Ghostty, kitty and WezTerm understand the same sequence.
# Bytes are walked under LC_ALL=C so multi-byte characters (accents or
# emoji in a folder name) encode one byte at a time, as the URL spec
# requires. Pure builtins — no process launch, safe on every prompt.
_osc7_report_cwd() {
  emulate -L zsh
  [[ -o interactive ]] || return 0
  [[ "$TERM" == (dumb|linux) ]] && return 0

  local encoded='' char hex i
  local LC_ALL=C
  for (( i = 1; i <= ${#PWD}; ++i )); do
    char="$PWD[i]"
    case "$char" in
      ([A-Za-z0-9/._~-]) encoded+="$char" ;;
      (*) printf -v hex '%%%02X' "'$char"; encoded+="$hex" ;;
    esac
  done

  printf '\e]7;file://%s%s\e\\' "$HOST" "$encoded"
}

# --- 2a. Record this window's directory ---------------------------
# Runs on every prompt, not just on cd, so the file always reflects the
# tab you most recently typed in — which is the tab you just pressed
# Cmd-T from. One small write to ~/.cache, no fork.
_cwd_record() {
  emulate -L zsh
  [[ -o interactive ]] || return 0
  local _CWD_WIN _CWD_TAB _CWD_PANE
  _cwd_parse_session || return 0
  print -r -- "$PWD" >| "$_CWD_STATE_DIR/w$_CWD_WIN" 2>/dev/null
}

# --- 2b. On startup, follow the tab we were opened from -----------
_cwd_restore() {
  emulate -L zsh
  [[ -o interactive ]] || return 0
  # Only for a new tab or split. A brand-new window (t0p0) stays at $HOME.
  local _CWD_WIN _CWD_TAB _CWD_PANE
  _cwd_parse_session || return 0
  (( _CWD_TAB > 0 || _CWD_PANE > 0 )) || return 0
  # Only when iTerm2 dropped us at home. If the profile is set to reuse
  # the previous directory, we are already correct — leave it alone.
  [[ "$PWD" == "$HOME" ]] || return 0

  local file="$_CWD_STATE_DIR/w$_CWD_WIN" dir
  [[ -r "$file" ]] || return 0
  dir="$(<"$file")"                       # read builtin, no fork
  [[ -n "$dir" && -d "$dir" && "$dir" != "$HOME" ]] || return 0
  cd -q -- "$dir"                         # -q: skip hooks, precmd handles the rest
}

_cwd_restore

add-zsh-hook chpwd  _osc7_report_cwd   # the instant you cd
add-zsh-hook precmd _osc7_report_cwd   # startup, plus dirs changed by a program
add-zsh-hook chpwd  _cwd_record
add-zsh-hook precmd _cwd_record
