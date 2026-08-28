# 20-tools.zsh — third-party tool integration
# ---------------------------------------------------------------

# --- zoxide: `z <fragment>` jumps to a directory you've visited ---
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# --- direnv: auto-loads/unloads .envrc per project directory ---
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# --- fzf: fuzzy finder. Ctrl+R history, Ctrl+T files, Alt+C cd ---
if command -v fzf >/dev/null; then
  source <(fzf --zsh) 2>/dev/null

  export FZF_DEFAULT_OPTS="
    --height=60% --layout=reverse --border=rounded --info=inline
    --prompt='  ' --pointer='▶' --marker='✓'
    --color=fg:-1,bg:-1,hl:#89b4fa
    --color=fg+:#cdd6f4,bg+:#313244,hl+:#89b4fa
    --color=info:#94e2d5,prompt:#cba6f7,pointer:#f38ba8
    --color=marker:#a6e3a1,spinner:#f5c2e7,header:#6c7086
    --color=border:#45475a"

  if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # Preview panes: files get syntax colors, directories get a tree
  command -v bat >/dev/null && \
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {}'"
  command -v eza >/dev/null && \
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}'"
fi

# --- bat: cat with syntax highlighting ---
if command -v bat >/dev/null; then
  export BAT_THEME="OneHalfDark"
  export BAT_STYLE="numbers,changes,header"
  # Colorize man pages too
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi
