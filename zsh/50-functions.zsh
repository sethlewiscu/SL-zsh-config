# 50-functions.zsh — task-shaped helpers
# ---------------------------------------------------------------

# mkcd — make a directory and enter it
mkcd() { mkdir -p "$1" && cd "$1"; }

# up N — go up N directory levels
up() { local n=${1:-1}; local p=""; for ((i=0;i<n;i++)); do p="../$p"; done; cd "$p"; }

# extract — unpack any archive without remembering the flags
extract() {
  [[ -f "$1" ]] || { echo "no such file: $1"; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.zip)            unzip "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.7z)             7z x "$1" ;;
    *) echo "don't know how to extract $1" ; return 1 ;;
  esac
}

# ff — fuzzy-find a file and open it in $EDITOR
ff() {
  local f; f=$(fzf --preview 'bat --style=numbers --color=always --line-range :300 {}') || return
  [[ -n "$f" ]] && ${EDITOR} "$f"
}

# fcd — fuzzy-find a directory and cd into it
fcd() {
  local d; d=$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=2 --color=always --icons {}') || return
  [[ -n "$d" ]] && cd "$d"
}

# fgb — fuzzy-pick a git branch and switch to it
fgb() {
  local b; b=$(git branch -a --format='%(refname:short)' | sed 's|^origin/||' | sort -u \
    | fzf --preview 'git log --oneline --graph --decorate -20 {}') || return
  [[ -n "$b" ]] && git switch "$b" 2>/dev/null || git switch -c "$b" --track "origin/$b"
}

# fkill — fuzzy-pick a process and kill it
fkill() {
  local pid; pid=$(ps -ef | sed 1d | fzf -m --header='select process(es) to kill' | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -${1:-15}
}

# --- API / JSON helpers ---

# api — GET a URL and pretty-print the JSON with colors
api() { curl -sS -H "Accept: application/json" "$@" | jq -C . | less -R; }

# cuapi — hit the ClickUp staging API. Needs $CLICKUP_TOKEN set.
# usage: cuapi /list/12345
cuapi() {
  [[ -z "$CLICKUP_TOKEN" ]] && { echo "set CLICKUP_TOKEN first"; return 1; }
  curl -sS -H "Authorization: $CLICKUP_TOKEN" -H "Accept: application/json" \
    "${CLICKUP_BASE}${1}" "${@:2}" | jq -C . | less -R
}

# jqf — fuzzy-explore a JSON file's structure interactively
jqf() {
  [[ -f "$1" ]] || { echo "usage: jqf <file.json>"; return 1; }
  jq -r 'paths(scalars) as $p | $p | join(".")' "$1" | sort -u \
    | fzf --preview "jq -C '.{}' '$1'"
}

# --- Notes / docs ---

# note — append a timestamped line to today's note file
note() {
  local dir="$HOME/Documents/notes"; mkdir -p "$dir"
  local f="$dir/$(date +%Y-%m-%d).md"
  if [[ $# -eq 0 ]]; then ${EDITOR} "$f"; return; fi
  echo "- $(date '+%H:%M') $*" >> "$f" && echo "→ $f"
}

# notes — fuzzy-search across all notes by content
notes() {
  local dir="$HOME/Documents/notes"
  rg --line-number --no-heading --color=always "" "$dir" 2>/dev/null \
    | fzf --ansi --delimiter=: --preview 'bat --color=always --highlight-line {2} {1}'
}

# --- Claude Code ---

# cw — create a git worktree and launch Claude Code inside it
cw() {
  [[ -z "$1" ]] && { echo "usage: cw <branch-name>"; return 1; }
  local root wt
  root=$(git rev-parse --show-toplevel) || return 1
  wt="${root}-wt-$1"
  git worktree add "$wt" -b "$1" && cd "$wt" && claude
}

# cwl — list worktrees with their branch and dirty state
cwl() {
  git worktree list --porcelain | awk '
    /^worktree /{wt=$2}
    /^branch /{sub("refs/heads/","",$2); print wt"\t"$2}'  \
  | while IFS=$'\t' read -r path branch; do
      local n; n=$(command git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      printf "%-50s %-25s %s\n" "$path" "$branch" "$([[ $n -gt 0 ]] && echo "● $n changed" || echo "clean")"
    done
}

# --- Reference ---

# cheat — print the custom commands this config adds
cheat() {
  cat <<'HELP'
NAVIGATION
  z <frag>      jump to a visited directory by fragment
  fcd           fuzzy-pick a directory and cd
  mkcd <dir>    make a directory and enter it
  up <n>        go up n levels
  d             list recent directory stack

FILES
  ll / la / lt  list / list all / tree (with git status per file)
  ff            fuzzy-find a file, open in editor
  cat <f>       syntax-highlighted (bat)
  extract <f>   unpack any archive
  trash <p>     delete recoverably (goes to Trash)

GIT
  gs            short status + tracking line
  gcur          which branch am I on
  gsync         fetch + prune + fast-forward pull (never rewrites)
  gl / gll      graph log (current / all branches)
  gap           stage hunk by hunk
  gundo         undo last commit, KEEP changes staged
  gwip/gunwip   park / unpark work in progress
  fgb           fuzzy-pick a branch and switch
  gclean-branches [--force]   remove merged local branches
  gwt / cwl     list worktrees (cwl adds dirty state)
  cw <branch>   new worktree + launch Claude Code

API / JSON
  api <url>     GET, pretty-print JSON, paged
  cuapi <path>  ClickUp staging API (needs $CLICKUP_TOKEN)
  jqf <file>    fuzzy-explore a JSON file's structure
  jqp           pretty-print piped JSON, colored + paged

NOTES
  note <text>   append timestamped line to today's note
  notes         fuzzy-search all notes

THEME
  theme         show current mode and whether it's following macOS
  theme auto    follow macOS light/dark (default)
  theme dark    pin to dark
  theme light   pin to light
  (prompt, iTerm2 colors, bat, delta, and fzf all switch together)

KEYS
  Ctrl+R        fuzzy search command history
  Ctrl+T        fuzzy insert a file path
  Alt+C         fuzzy cd
  ↑ / ↓         search history matching what you've typed
  →             accept the grey autosuggestion

GUARDRAILS (bypass any with:  command git ... )
  force push, reset --hard, clean -f, filter-branch/repo,
  gc --prune, branch -D, rm -rf   → all require typed confirmation
HELP
}
