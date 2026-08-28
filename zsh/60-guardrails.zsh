# 60-guardrails.zsh — confirmation gates on destructive operations
# ---------------------------------------------------------------
# These wrap `git` and `rm` as SHELL FUNCTIONS. Shell functions are not
# inherited by scripts or subprocesses, so nothing you run (Claude Code,
# CI, make, npm) is affected. Only what YOU type interactively is gated.
#
# Bypass any gate for one command with:  command git ...   /   command rm ...
# ---------------------------------------------------------------

_gr_warn()  { print -P "%F{yellow}⚠  $1%f" >&2; }
_gr_die()   { print -P "%F{red}✖  $1%f" >&2; }
_gr_ok()    { print -P "%F{green}✔  $1%f" >&2; }

# Require the user to type an exact confirmation string.
_gr_confirm_typed() {
  local expect="$1" answer
  print -Pn "%F{yellow}   type %B${expect}%b to confirm (anything else aborts): %f" >&2
  read -r answer
  [[ "$answer" == "$expect" ]] && return 0
  _gr_die "aborted."
  return 1
}

_gr_confirm_yes() {
  local answer
  print -Pn "%F{yellow}   proceed? [y/N] %f" >&2
  read -r answer
  [[ "$answer" == [yY] ]] && return 0
  _gr_die "aborted."
  return 1
}

# ---------------------------------------------------------------
# git wrapper
# ---------------------------------------------------------------
git() {
  local sub="$1"; shift 2>/dev/null
  local args=("$@")
  local all=("$sub" "$@")

  case "$sub" in

    push)
      if [[ " ${args[*]} " == *" --force "* || " ${args[*]} " == *" -f "* ]]; then
        local br remote_ahead
        br=$(command git branch --show-current 2>/dev/null)
        _gr_warn "FORCE PUSH on branch '${br:-<detached>}'"
        _gr_warn "this overwrites the remote branch; commits only on the remote are lost"
        command git fetch --quiet origin "$br" 2>/dev/null
        remote_ahead=$(command git rev-list --count "HEAD..origin/$br" 2>/dev/null)
        [[ -n "$remote_ahead" && "$remote_ahead" != "0" ]] && \
          _gr_warn "$remote_ahead commit(s) exist on origin/$br that you do NOT have"
        _gr_warn "safer alternative: git push --force-with-lease"
        _gr_confirm_typed "$br" || return 1
      fi
      ;;

    reset)
      if [[ " ${args[*]} " == *" --hard "* ]]; then
        local dirty
        dirty=$(command git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        _gr_warn "git reset --hard DISCARDS all uncommitted changes on disk"
        [[ "$dirty" != "0" ]] && _gr_warn "$dirty file(s) currently modified/untracked would be affected"
        _gr_warn "safer alternative: git stash push -u   (parks changes, recoverable)"
        _gr_confirm_typed "reset" || return 1
      fi
      ;;

    clean)
      if [[ " ${args[*]} " == *"f"* ]]; then
        _gr_warn "git clean DELETES untracked files from disk permanently"
        echo "   would delete:" >&2
        command git clean -nd "${args[@]//-f/}" 2>/dev/null | sed 's/^/   /' >&2
        _gr_confirm_typed "clean" || return 1
      fi
      ;;

    # --- The history-rewrite family: your documented data-loss path ---
    filter-branch|filter-repo)
      _gr_die "HISTORY REWRITE: git $sub"
      _gr_warn "this resets the working tree. Files tracked in git but removed from"
      _gr_warn "history are DELETED FROM DISK, not merely untracked."
      _gr_warn "A later 'git gc --prune=now' makes that permanent and unrecoverable."
      echo "" >&2
      _gr_warn "required first: copy affected paths OUTSIDE the repo (cp -a to a temp dir)"
      _gr_warn "required after: verify files still exist on disk BEFORE any gc/prune"
      echo "" >&2
      _gr_confirm_typed "I HAVE A BACKUP" || return 1
      ;;

    gc)
      if [[ " ${args[*]} " == *"--prune"* ]]; then
        _gr_die "git gc --prune: THIS IS THE POINT OF NO RETURN"
        _gr_warn "destroys reflog and unreachable objects — all git-side recovery ends here"
        _gr_warn "only run this after confirming nothing needed was lost"
        _gr_confirm_typed "no recovery needed" || return 1
      fi
      ;;

    rebase)
      if [[ " ${args[*]} " == *" --onto "* || " ${args[*]} " == *" -i "* ]]; then
        _gr_warn "interactive/onto rebase rewrites commits; dropped commits can drop files"
        _gr_confirm_yes || return 1
      fi
      ;;

    branch)
      if [[ " ${args[*]} " == *" -D "* ]]; then
        _gr_warn "git branch -D force-deletes a branch even if UNMERGED (commits orphaned)"
        _gr_warn "safer alternative: git branch -d   (refuses if unmerged)"
        _gr_confirm_yes || return 1
      fi
      ;;

    checkout|switch)
      if [[ " ${args[*]} " == *" --force "* || " ${args[*]} " == *" -f "* ]]; then
        _gr_warn "force checkout discards uncommitted changes in the working tree"
        _gr_confirm_yes || return 1
      fi
      ;;
  esac

  command git "${all[@]}"
}

# ---------------------------------------------------------------
# rm wrapper — gate recursive+force deletes
# ---------------------------------------------------------------
rm() {
  local recursive=0 force=0 arg
  for arg in "$@"; do
    [[ "$arg" == -* && "$arg" != --* ]] && {
      [[ "$arg" == *[rR]* ]] && recursive=1
      [[ "$arg" == *f* ]] && force=1
    }
    [[ "$arg" == "--recursive" ]] && recursive=1
    [[ "$arg" == "--force" ]] && force=1
  done

  if (( recursive && force )); then
    local targets=() n
    for arg in "$@"; do [[ "$arg" != -* ]] && targets+=("$arg"); done

    # Hard block on paths that should never be recursively force-deleted
    for arg in "${targets[@]}"; do
      case "${arg:A}" in
        / | /Users | "$HOME" | /System* | /Applications | /opt | /usr | /etc)
          _gr_die "refusing: rm -rf on protected path '$arg'"
          _gr_die "if you truly mean it: command rm -rf '$arg'"
          return 1 ;;
      esac
    done

    _gr_warn "rm -rf — permanent deletion, does NOT go to Trash"
    for arg in "${targets[@]}"; do
      n=$(command find "$arg" 2>/dev/null | wc -l | tr -d ' ')
      print -P "   %F{cyan}${arg:A}%f  (~${n} items)" >&2
    done
    _gr_warn "safer alternative: trash <path>  (recoverable from Finder Trash)"
    _gr_confirm_typed "delete" || return 1
  fi

  command rm "$@"
}

# trash — the recoverable alternative. Moves to macOS Trash.
trash() {
  [[ $# -eq 0 ]] && { echo "usage: trash <path>..."; return 1; }
  local p
  for p in "$@"; do
    [[ -e "$p" ]] || { _gr_die "no such path: $p"; continue; }
    command mv "$p" "$HOME/.Trash/$(basename "$p").$(date +%s)" && _gr_ok "trashed: $p"
  done
}
