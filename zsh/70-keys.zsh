# 70-keys.zsh — keybindings
# NOTE: must load AFTER the plugins that define the widgets.
# ---------------------------------------------------------------

bindkey -e   # emacs-style line editing (Ctrl+A start, Ctrl+E end, Ctrl+K kill)

# Up/Down search history for lines matching what you've typed so far
if [[ -n "${functions[history-substring-search-up]}" ]]; then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P'   history-substring-search-up
  bindkey '^N'   history-substring-search-down
fi

# → accepts the grey autosuggestion; Ctrl+→ accepts one word
bindkey '^[[C' forward-char
bindkey '^[f'  forward-word

# Word-wise navigation with Option+arrow (matches macOS habit)
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

# Ctrl+U clears the whole line (bash behavior, not zsh's kill-to-start)
bindkey '^U' kill-whole-line

# Edit the current command line in $EDITOR with Ctrl+X Ctrl+E
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
