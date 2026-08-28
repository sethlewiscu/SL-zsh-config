# ~/.p10k.zsh — Powerlevel10k prompt
# Spec: two-line framed | path + git only | moderate git detail
# Re-run the interactive wizard any time with: p10k configure
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
  # SEGMENTS — deliberately minimal.
  # Left line 1:  directory + git
  # Left line 2:  the prompt character you type after
  # Right:        nothing. No clock, no versions, no timers.
  # =============================================================
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir
    vcs
    newline
    prompt_char
  )
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=none
  typeset -g POWERLEVEL9K_BACKGROUND=                    # transparent, no blocks
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION='${P9K_VISUAL_IDENTIFIER}'

  # =============================================================
  # FRAME — the ╭─ / ╰─ brackets plus a ruler between commands.
  # This is the readability feature: when you scroll back through a
  # long Claude answer, the ruler marks exactly where it started.
  # =============================================================
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%F{240}╭─%f'
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{240}╰─%f'
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%F{240}├─%f'

  typeset -g POWERLEVEL9K_SHOW_RULER=true
  typeset -g POWERLEVEL9K_RULER_CHAR='─'
  typeset -g POWERLEVEL9K_RULER_FOREGROUND=236

  # =============================================================
  # PROMPT CHARACTER
  # Turns red when the last command failed — a free error indicator
  # that costs no horizontal space.
  # =============================================================
  typeset -g POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_{LEFT,RIGHT}_WHITESPACE=

  # =============================================================
  # DIRECTORY
  # Shortens from the left when deep, always keeping the last two
  # segments plus anchors (the folder holding .git, package.json, etc).
  # =============================================================
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=39
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=39
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

    # Color: green = clean, yellow = dirty, red = conflicted/rebasing
    local meta clean modified conflicted
    if (( $1 )); then
      meta='%f' clean='%76F' modified='%178F' conflicted='%196F'
    else
      meta='%244F' clean='%244F' modified='%244F' conflicted='%244F'
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
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED,LOADING}_FOREGROUND=244

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
