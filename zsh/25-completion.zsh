# 25-completion.zsh — tab completion behavior
# ---------------------------------------------------------------

# Menu you arrow through, rather than a static list dump
zstyle ':completion:*' menu select
zmodload zsh/complist

# Case-insensitive, then partial-word, then substring matching
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Group results under headings, colorized
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*:messages'     format '%F{yellow}%d%f'
zstyle ':completion:*:warnings'     format '%F{red}no matches: %d%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Cache slow completions (helps gh, docker, aws)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"
mkdir -p "$HOME/.cache/zsh"

# Don't offer files already on the command line
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
# Complete process names for kill
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Arrow keys inside the completion menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
