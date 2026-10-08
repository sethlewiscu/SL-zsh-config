# 30-aliases.zsh — everyday shortcuts
# ---------------------------------------------------------------

# --- Listing (eza = ls with git status per file) ---
if command -v eza >/dev/null; then
  # ls stays the real ls: eza's flags differ (e.g. -t needs a value), which breaks ls -lt.
  alias ls='ls -G'
  alias ll='eza -l --icons --group-directories-first --git --time-style=long-iso'
  alias la='eza -la --icons --group-directories-first --git --time-style=long-iso'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
  alias ltt='eza --tree --level=3 --icons --group-directories-first'
  alias lsize='eza -la --icons --sort=size --reverse'
  alias lnew='eza -la --icons --sort=modified --reverse'
else
  alias ll='ls -lh'; alias la='ls -lah'
fi

# --- Viewing ---
command -v bat >/dev/null && { alias cat='bat --paging=never'; alias catp='bat'; }

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias d='dirs -v | head -10'

# --- Safety-flavored defaults ---
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'

# --- Search ---
alias grep='grep --color=auto'
command -v rg >/dev/null && alias rgi='rg -i'
command -v fd >/dev/null && alias fdh='fd --hidden --no-ignore'

# --- JSON / API work ---
alias jqp='jq -C . | less -R'                 # pretty-print JSON, paged, colored
alias jqk='jq -r "keys[]"'                    # list top-level keys
alias urlencode='python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))"'
alias urldecode='python3 -c "import sys,urllib.parse;print(urllib.parse.unquote(sys.argv[1]))"'
# curl that shows status + timing, pretty-prints JSON body
alias curljson='curl -sS -H "Accept: application/json"'

# --- ClickUp staging (per your global notes) ---
export CLICKUP_BASE="https://api.clickup-stg.com/api/v2"
export CLICKUP_STG_TEAM="333"

# --- Claude Code ---
alias c='claude'
alias cr='claude --resume'
alias cc='claude --continue'
alias cdang='claude --dangerously-skip-permissions'

# --- Config editing ---
alias zshconf='${EDITOR} ~/.config/zsh'
alias zshreload='exec zsh'
alias p10kconf='p10k configure'

# --- Misc ---
alias path='echo $PATH | tr ":" "\n"'
alias ports='lsof -iTCP -sTCP:LISTEN -P -n'
alias myip='curl -s https://ifconfig.me; echo'
alias now='date "+%Y-%m-%d %H:%M:%S"'
alias week='date "+week %V of %Y"'
