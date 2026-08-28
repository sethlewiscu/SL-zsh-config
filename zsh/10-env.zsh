# 10-env.zsh — environment, paths, history
# ---------------------------------------------------------------

export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-FRX"          # -F quit if one screen, -R keep colors, -X no clear
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# --- PATH (deduped automatically by zsh's typeset -U) ---
typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)
export PATH

# --- History ---
# Big, shared, deduped, timestamped. Timestamps matter: they let you
# correlate a command with an incident or a log entry after the fact.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY        # record timestamp + duration
setopt INC_APPEND_HISTORY      # write as you go, not just on exit
setopt SHARE_HISTORY           # share across open terminals live
setopt HIST_IGNORE_ALL_DUPS    # drop older duplicate of a repeated command
setopt HIST_IGNORE_SPACE       # leading space = don't record (for secrets)
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY             # expand !! into the line, don't run it blind
setopt HIST_FCNTL_LOCK

# --- Directory navigation ---
setopt AUTO_CD                 # type a directory name to cd into it
setopt AUTO_PUSHD              # every cd pushes onto a stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
DIRSTACKSIZE=20

# --- Globbing / misc ---
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB
setopt INTERACTIVE_COMMENTS    # allow # comments at the prompt
setopt NO_BEEP
unsetopt CORRECT_ALL           # zsh's autocorrect guesses badly; off
