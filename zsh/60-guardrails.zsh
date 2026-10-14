# 60-guardrails.zsh — confirmation gates on destructive operations
# ---------------------------------------------------------------
# These wrap `git` and `rm` as SHELL FUNCTIONS. Shell functions are not
# inherited by scripts or subprocesses, so make, npm and CI are not affected.
#
# Claude Code IS affected: its agent shells load a snapshot of this config,
# wrappers included. The snapshot drops functions whose names start with `_`,
# so the helpers below use a plain `gr_` prefix. In an agent shell (CLAUDECODE
# set) the confirm prompts refuse instead of waiting for input an agent can't
# type, so agents get a clear "blocked" rather than a silent no-op.
#
# Bypass any gate for one command with:  command git ...   /   command rm ...
# ---------------------------------------------------------------

gr_warn()  { print -P "%F{yellow}⚠  $1%f" >&2; }
gr_die()   { print -P "%F{red}✖  $1%f" >&2; }
gr_ok()    { print -P "%F{green}✔  $1%f" >&2; }

# Agent shells can't answer a prompt: refuse and say who should run it.
gr_agent_refuse() {
  [[ -n "$CLAUDECODE" ]] || return 1
  gr_die "blocked in an agent shell: needs a human confirmation."
  gr_die "hand this command to the user to run; don't bypass it with 'command'."
  return 0
}

# Require the user to type an exact confirmation string.
gr_confirm_typed() {
  local expect="$1" answer
  gr_agent_refuse && return 1
  print -Pn "%F{yellow}   type %B${expect}%b to confirm (anything else aborts): %f" >&2
  read -r answer
  [[ "$answer" == "$expect" ]] && return 0
  gr_die "aborted."
  return 1
}

gr_confirm_yes() {
  local answer
  gr_agent_refuse && return 1
  print -Pn "%F{yellow}   proceed? [y/N] %f" >&2
  read -r answer
  [[ "$answer" == [yY] ]] && return 0
  gr_die "aborted."
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
        gr_warn "FORCE PUSH on branch '${br:-<detached>}'"
        gr_warn "this overwrites the remote branch; commits only on the remote are lost"
        command git fetch --quiet origin "$br" 2>/dev/null
        remote_ahead=$(command git rev-list --count "HEAD..origin/$br" 2>/dev/null)
        [[ -n "$remote_ahead" && "$remote_ahead" != "0" ]] && \
          gr_warn "$remote_ahead commit(s) exist on origin/$br that you do NOT have"
        gr_warn "safer alternative: git push --force-with-lease"
        gr_confirm_typed "$br" || return 1
      fi
      ;;

    reset)
      if [[ " ${args[*]} " == *" --hard "* ]]; then
        local dirty
        dirty=$(command git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        gr_warn "git reset --hard DISCARDS all uncommitted changes on disk"
        [[ "$dirty" != "0" ]] && gr_warn "$dirty file(s) currently modified/untracked would be affected"
        gr_warn "safer alternative: git stash push -u   (parks changes, recoverable)"
        gr_confirm_typed "reset" || return 1
      fi
      ;;

    clean)
      if [[ " ${args[*]} " == *"f"* ]]; then
        gr_warn "git clean DELETES untracked files from disk permanently"
        echo "   would delete:" >&2
        command git clean -nd "${args[@]//-f/}" 2>/dev/null | sed 's/^/   /' >&2
        gr_confirm_typed "clean" || return 1
      fi
      ;;

    # --- The history-rewrite family: your documented data-loss path ---
    filter-branch|filter-repo)
      gr_die "HISTORY REWRITE: git $sub"
      gr_warn "this resets the working tree. Files tracked in git but removed from"
      gr_warn "history are DELETED FROM DISK, not merely untracked."
      gr_warn "A later 'git gc --prune=now' makes that permanent and unrecoverable."
      echo "" >&2
      gr_warn "required first: copy affected paths OUTSIDE the repo (cp -a to a temp dir)"
      gr_warn "required after: verify files still exist on disk BEFORE any gc/prune"
      echo "" >&2
      gr_confirm_typed "I HAVE A BACKUP" || return 1
      ;;

    gc)
      if [[ " ${args[*]} " == *"--prune"* ]]; then
        gr_die "git gc --prune: THIS IS THE POINT OF NO RETURN"
        gr_warn "destroys reflog and unreachable objects — all git-side recovery ends here"
        gr_warn "only run this after confirming nothing needed was lost"
        gr_confirm_typed "no recovery needed" || return 1
      fi
      ;;

    rebase)
      if [[ " ${args[*]} " == *" --onto "* || " ${args[*]} " == *" -i "* ]]; then
        gr_warn "interactive/onto rebase rewrites commits; dropped commits can drop files"
        gr_confirm_yes || return 1
      fi
      ;;

    branch)
      if [[ " ${args[*]} " == *" -D "* ]]; then
        gr_warn "git branch -D force-deletes a branch even if UNMERGED (commits orphaned)"
        gr_warn "safer alternative: git branch -d   (refuses if unmerged)"
        gr_confirm_yes || return 1
      fi
      ;;

    checkout|switch)
      if [[ " ${args[*]} " == *" --force "* || " ${args[*]} " == *" -f "* ]]; then
        gr_warn "force checkout discards uncommitted changes in the working tree"
        gr_confirm_yes || return 1
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
          gr_die "refusing: rm -rf on protected path '$arg'"
          gr_die "if you truly mean it: command rm -rf '$arg'"
          return 1 ;;
      esac
    done

    gr_warn "rm -rf — permanent deletion, does NOT go to Trash"
    for arg in "${targets[@]}"; do
      n=$(command find "$arg" 2>/dev/null | wc -l | tr -d ' ')
      print -P "   %F{cyan}${arg:A}%f  (~${n} items)" >&2
    done
    gr_warn "safer alternative: trash <path>  (recoverable from Finder Trash)"
    gr_confirm_typed "delete" || return 1
  fi

  command rm "$@"
}

# trash — the recoverable alternative. Moves to macOS Trash.
trash() {
  [[ $# -eq 0 ]] && { echo "usage: trash <path>..."; return 1; }
  local p
  for p in "$@"; do
    [[ -e "$p" ]] || { gr_die "no such path: $p"; continue; }
    command mv "$p" "$HOME/.Trash/$(basename "$p").$(date +%s)" && gr_ok "trashed: $p"
  done
}
