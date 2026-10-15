# ~/.p10k.zsh — Powerlevel10k prompt
# Theme: "Starfleet" — colors live in ~/.config/zsh/12-palette.zsh
# Spec: two-line framed | path + git | alert, timer, stardate on the right
# Don't re-run `p10k configure`: it would overwrite this hand-built file.
# ---------------------------------------------------------------

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
  autoload -Uz is-at-least && is-at-least 5.1 || return

  # =============================================================
  # PALETTE — follows macOS light/dark.
  # $_THEME_MODE is set by ~/.config/zsh/15-theme.zsh, which loads first
  # and calls `p10k reload` whenever the system appearance changes.
  # Colors are 24-bit hex, picked from the palette by role name.
  # =============================================================
  # Global, not local: the segment functions below run at prompt time,
  # long after this setup function has returned. Locals would be gone.
  typeset -gA _tc
  if [[ ${_THEME_MODE:-dark} == light ]]; then
    _tc=("${(@kv)_PAL_LIGHT}")
  else
    _tc=("${(@kv)_PAL_DARK}")
  fi

  # The delta. md-navigation is the Nerd Font arrowhead closest to the
  # Starfleet badge; terminals we haven't set up with that font get ▲.
  typeset -g _sf_glyph='▲'
  [[ $TERM_PROGRAM == (iTerm.app|vscode) ]] && _sf_glyph=$'\U000F0390'

  # =============================================================
  # SEGMENTS
  # Left line 1:   directory + git
  # Left line 2:   the delta you type after
  # Right line 1:  [alert] [timer] stardate — usually just the stardate
  # =============================================================
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir
    vcs
    newline
    sf_delta
  )
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    sf_alert
    command_execution_time
    sf_stardate
    newline
  )

  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=none
  typeset -g POWERLEVEL9K_BACKGROUND=                    # transparent, no blocks
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR='  '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION='${P9K_VISUAL_IDENTIFIER}'

  # =============================================================
  # FRAME — the ╭─ / ╰─ brackets plus a ruler between commands.
  # This is the readability feature: when you scroll back through a
  # long Claude answer, the ruler marks exactly where it started.
  #
  # The ruler is drawn by _sf_ruler below, not by p10k: p10k's ruler
  # can only repeat a single character, and ours carries the delta.
  # =============================================================
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false     # _sf_ruler prints it
  typeset -g POWERLEVEL9K_SHOW_RULER=false

  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{$_tc[frame]}╭─ %f"
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{$_tc[frame]}╰─ %f"
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX="%F{$_tc[frame]}├─ %f"

  # Blank line + ────────── ▲ ─── before every prompt except the first in
  # a new terminal (nothing above it to separate from).
  function _sf_ruler() {
    if (( ! $+_sf_ruler_armed )); then
      typeset -g _sf_ruler_armed=1
      return
    fi
    # One column short of full width: writing the last column can make
    # some terminals wrap and leave an extra blank line.
    local -i w=$(( COLUMNS - 1 ))
    (( w > 10 )) || return
    print -P -- "\n%F{$_tc[ruler]}${(l:w-6::─:)}%F{$_tc[frame]} $_sf_glyph %F{$_tc[ruler]}───%f"
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _sf_ruler

  # =============================================================
  # EXIT STATUS — the delta and the red-alert readout
  # Codes above 128 mean "killed by signal (code − 128)". Signals are
  # matched by name because the numbers differ by OS: Ctrl-Z is 146 on
  # macOS, 148 on Linux. Ctrl-C and Ctrl-Z are you cancelling, not a
  # failure, so they stay silver and the delta stays gold.
  #
  # _p9k__status is p10k's internal copy of $?, captured before any
  # other precmd hook can overwrite it.
  # =============================================================
  typeset -gA _sf_exit_words=(
    1 failed  2 'usage error'  126 'not permitted'  127 'not found'
  )
  typeset -gA _sf_signal_words=(
    INT interrupted  TSTP suspended  HUP 'hung up'  QUIT quit  ABRT aborted
    KILL killed  SEGV crashed  BUS crashed  PIPE 'broken pipe'  TERM terminated
  )
  typeset -ga _sf_benign=(INT TSTP)

  # Sets REPLY to the words for the last exit code; returns 0 if it
  # was a real failure, 1 if success or a benign cancel.
  function _sf_status() {
    local -i code=$_p9k__status
    REPLY=
    (( code )) || return 1
    if (( code > 128 && code - 127 <= $#signals )); then
      local sig=$signals[code-127]       # $signals[1] is EXIT (0)
      REPLY=${_sf_signal_words[$sig]:-${(L)sig}}
      (( $_sf_benign[(Ie)$sig] )) && return 1
    else
      REPLY=${_sf_exit_words[$code]:-failed}
    fi
    return 0
  }

  function prompt_sf_alert() {
    (( _p9k__status )) || return
    if _sf_status; then
      p10k segment -f $_tc[alert] -t "ALERT $_p9k__status · $REPLY"
    else
      p10k segment -f $_tc[meta] -t "$_p9k__status · $REPLY"
    fi
  }

  function prompt_sf_delta() {
    if _sf_status; then
      p10k segment -f $_tc[alert] -t $_sf_glyph
    else
      p10k segment -f $_tc[sym] -t $_sf_glyph
    fi
  }
  function instant_prompt_sf_delta() { p10k segment -f $_tc[sym] -t $_sf_glyph }

  # =============================================================
  # STARDATE — SD YY.MM.DD. %D{…} is expanded each time the prompt is
  # drawn, so it rolls over at midnight without any work on our side.
  # =============================================================
  function prompt_sf_stardate() { p10k segment -f $_tc[meta] -t 'SD %D{%y.%m.%d}' }
  function instant_prompt_sf_stardate() { prompt_sf_stardate }

  # =============================================================
  # TIMER — only for commands that took 3s or more. T+2m4s, T+12s.
  # =============================================================
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$_tc[meta]
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_CONTENT_EXPANSION='T+${P9K_CONTENT// /}'

  # =============================================================
  # DIRECTORY
  # Shortens from the left when deep, always keeping the last two
  # segments plus anchors (the folder holding .git, package.json, etc).
  # =============================================================
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$_tc[dir]
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=$_tc[dir_dim]
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$_tc[dir]
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=60
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50
  local anchor_files=(
    .git .node-version .python-version .go-version .ruby-version
    package.json pyproject.toml Cargo.toml go.mod Makefile
    .envrc .claude CLAUDE.md
  )
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER="(${(j:|:)anchor_files})"
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=false
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=false
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3       # lock icon if not writable
  typeset -g POWERLEVEL9K_DIR_CLASSES=()

  # =============================================================
  # GIT — "moderate" detail, per spec:
  #   branch name
  #   ⇡N  commits ahead of remote   (you have N to push)
  #   ⇣N  commits behind remote     (you have N to pull)
  #   ●   working tree has changes  (any kind: staged/unstaged/untracked)
  #   plus loud markers for states that are easy to lose work in:
  #   detached HEAD, mid-rebase, mid-merge, conflicts, stashes
  # =============================================================
  function my_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      # gitstatus not ready yet — show p10k's own placeholder
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    # Color: blue = clean, yellow alert = dirty, red alert = conflicted/rebasing
    local meta clean modified conflicted
    if (( $1 )); then
      meta="%F{$_tc[meta]}" clean="%F{$_tc[git]}" modified="%F{$_tc[dirty]}" conflicted="%F{$_tc[alert]}"
    else
      meta="%F{$_tc[meta]}" clean="%F{$_tc[meta]}" modified="%F{$_tc[meta]}" conflicted="%F{$_tc[meta]}"
    fi

    local res

    # --- Branch, tag, or detached commit ---
    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      (( ${#branch} > 40 )) && branch[19,-19]="…"
      res+="${clean}  ${branch//\%/%%}"
    elif [[ -n $VCS_STATUS_TAG ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      (( ${#tag} > 32 )) && tag[13,-13]="…"
      res+="${meta}  ${tag//\%/%%}"
    else
      # No branch and no tag = detached HEAD. Easy to lose commits here.
      res+="${conflicted} DETACHED ${VCS_STATUS_COMMIT[1,8]}"
    fi

    # --- Remote divergence ---
    (( VCS_STATUS_COMMITS_AHEAD  )) && res+=" ${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
    (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"

    # --- Single dirty indicator (moderate detail) ---
    local dirty=$(( VCS_STATUS_HAS_STAGED + VCS_STATUS_HAS_UNSTAGED + VCS_STATUS_HAS_UNTRACKED ))
    (( dirty )) && res+=" ${modified}●"

    # --- Loud states: these can cost you work ---
    (( VCS_STATUS_HAS_CONFLICTED )) && res+=" ${conflicted}✖${VCS_STATUS_NUM_CONFLICTED} conflict"
    [[ -n $VCS_STATUS_ACTION ]]     && res+=" ${conflicted}[${VCS_STATUS_ACTION}]"
    (( VCS_STATUS_STASHES ))        && res+=" ${meta}*${VCS_STATUS_STASHES}"

    # --- No upstream configured: your pushes have nowhere to go ---
    [[ -z $VCS_STATUS_REMOTE_BRANCH && -n $VCS_STATUS_LOCAL_BRANCH ]] && res+=" ${meta}(no upstream)"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null

  # Don't scan huge repos for untracked files (keeps the prompt instant)
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT='…'
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_BACKGROUND=
  # The formatter above emits its own branch icon and colors, so suppress
  # p10k's built-in identifier (it defaults to black = invisible on dark bg).
  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED,LOADING}_FOREGROUND=$_tc[meta]

  # =============================================================
  # BEHAVIOR
  # =============================================================
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off       # keep full scrollback history
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ! $+functions[p10k] )) || p10k reload
}

typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
