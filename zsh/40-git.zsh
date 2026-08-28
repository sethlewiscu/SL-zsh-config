# 40-git.zsh — git & GitHub workflow
# ---------------------------------------------------------------

# Oh My Zsh's git plugin defines some of these names as aliases already.
# An alias shadows a function definition at parse time, so clear them first.
for _a in gsync gclean-branches gundo gwip gunwip gopen gwt gwta gwtr gcur; do
  unalias "$_a" 2>/dev/null
done
unset _a

# --- Core ---
alias g='git'
alias gs='git status -sb'                    # short status + branch/tracking line
alias gss='git status'
alias ga='git add'
alias gaa='git add -A'
alias gap='git add -p'                       # stage hunk-by-hunk, interactively
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'

# --- Branches ---
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'
# Which branch am I actually on? (your global notes: always verify)
alias gcur='git branch --show-current'

# --- Sync ---
alias gf='git fetch --all --prune'
alias gpl='git pull --ff-only'
alias gp='git push'
alias gpu='git push -u origin HEAD'

# --- History / inspection ---
alias gl='git log --oneline --graph --decorate -20'
alias gll='git log --oneline --graph --decorate --all -40'
alias glp='git log -p'
alias gd='git diff'
alias gds='git diff --staged'
alias gsh='git show'
alias gwho='git shortlog -sn --no-merges'

# --- Stash ---
alias gst='git stash push -u'                # -u includes untracked files
alias gstl='git stash list'
alias gstp='git stash pop'

# --- Worktrees (you use these with Claude Code) ---
alias gwt='git worktree list'
alias gwta='git worktree add'
alias gwtr='git worktree remove'

# --- GitHub CLI ---
alias ghpr='gh pr create --fill'
alias ghprv='gh pr view --web'
alias ghprl='gh pr list'
alias ghprc='gh pr checks'
alias ghrv='gh repo view --web'

# ---------------------------------------------------------------
# Functions
# ---------------------------------------------------------------

# gsync — safe sync: fetch, prune, fast-forward only. Never rewrites.
gsync() {
  git fetch --all --prune || return 1
  local br; br=$(git branch --show-current)
  echo "on branch: ${br:-<detached HEAD>}"
  git pull --ff-only && git status -sb
}

# gclean-branches — delete local branches already merged into main/master.
# Dry-run by default. Pass --force to actually delete.
gclean-branches() {
  local base; base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  base="${base:-main}"
  local merged
  merged=$(git branch --merged "$base" | grep -vE "^\*|^\s*($base|master|main)$" | tr -d ' ')
  if [[ -z "$merged" ]]; then echo "no merged branches to clean (base: $base)"; return 0; fi
  echo "merged into $base:"; echo "$merged" | sed 's/^/  /'
  if [[ "$1" == "--force" ]]; then
    echo "$merged" | xargs -n1 git branch -d
  else
    echo "\ndry run. re-run with: gclean-branches --force"
  fi
}

# gundo — undo the last commit but KEEP all the changes staged.
# This is the safe undo. It never touches your files on disk.
gundo() {
  git reset --soft HEAD~1 && echo "last commit undone; changes kept staged" && git status -sb
}

# gwip / gunwip — park work-in-progress as a throwaway commit
gwip()   { git add -A && git commit -m "wip: $(date '+%Y-%m-%d %H:%M')" --no-verify; }
gunwip() { git log -1 --pretty=%s | grep -q '^wip:' && gundo || echo "last commit is not a wip"; }

# gopen — open the current repo's remote in a browser
gopen() { gh repo view --web 2>/dev/null || open "$(git remote get-url origin | sed 's/\.git$//')"; }
