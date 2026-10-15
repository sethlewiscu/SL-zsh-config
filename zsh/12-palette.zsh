# 12-palette.zsh — the one place colors are defined
# ---------------------------------------------------------------
# Theme: "Starfleet" — original-series uniform colors on modern
# Starfleet structure. Dark = bridge at night (deep navy). Light =
# starship hull (warm off-white).
#
# Everything else reads from here: the prompt (~/.p10k.zsh), fzf and
# autosuggestions (15-theme.zsh), and the generated iTerm profile.
# Change a color here, not there.
#
# Values are 24-bit hex. iTerm, Cursor and VS Code all render them
# exactly; there is no 256-color approximation.
#
# Roles, and what they mean on screen:
#   bg / fg   terminal background and default text
#   ruler     line between commands — decorative, deliberately faint
#   frame     the ╭─ ╰─ brackets — decorative
#   meta      secondary text: stardate, timer, stashes, "no upstream"
#   dir       current folder           (command gold — where you are)
#   dir_dim   shortened path segments
#   git       clean branch             (sciences blue — all checks out)
#   dirty     uncommitted changes      (yellow alert)
#   alert     failures, conflicts, detached HEAD — red is ONLY this
#   sym       the delta you type after, when all is well
#
# Check readability after any change:  ~/.dotfiles/bin/theme-preview --check
# ---------------------------------------------------------------

typeset -gA _PAL_DARK=(
  bg       '#18233A'
  fg       '#D5DCE6'
  ruler    '#2F3E59'
  frame    '#5B6C88'
  meta     '#8D9AB0'
  dir      '#F0BE4A'
  dir_dim  '#A88F5A'
  git      '#5AA8F0'
  dirty    '#FF9E2C'
  alert    '#FF5C5C'
  sym      '#F0BE4A'
)

typeset -gA _PAL_LIGHT=(
  bg       '#F3EFE6'
  fg       '#1E2632'
  ruler    '#DAD3C4'
  frame    '#A39C8E'
  meta     '#666A73'
  dir      '#875C00'
  dir_dim  '#74633F'
  git      '#1E5FAF'
  dirty    '#B84500'
  alert    '#BF262C'
  sym      '#875C00'
)

# --- Terminal colors (iTerm profile, via `theme build`) -------------
#   bold         text a program prints in bold
#   cursor       block cursor — command gold, like the delta
#   cursor_text  the letter under the cursor
#   sel_bg/fg    highlighted (selected) text
#
# The 16 ANSI colors are the fixed set every command-line program picks
# from (git, ls, test runners, …). Normal + bright of each. Where an
# ANSI color IS a theme role (red = alert, yellow = gold, blue =
# sciences), it's copied from the role so the two can't drift apart.
#
# black / white are mostly used as backgrounds and fills, so the one
# that matches the background (black in dark, white in light) is
# deliberately close to it.
#
# In light mode "bright" can't mean lighter — lighter on off-white is
# harder to read. There, bright = same darkness, a little more vivid.

_PAL_DARK+=(
  bold         '#F2F5FA'
  cursor       $_PAL_DARK[sym]
  cursor_text  $_PAL_DARK[bg]
  sel_bg       '#2F4A74'
  sel_fg       '#F2F5FA'

  black        '#2A3852'   br_black    '#7D8BA3'
  red          $_PAL_DARK[alert]   br_red      '#FF8A80'
  green        '#7CC77A'   br_green    '#A3DC9B'
  yellow       $_PAL_DARK[dir]     br_yellow   '#FFD878'
  blue         $_PAL_DARK[git]     br_blue     '#8AC2FF'
  magenta      '#C792EA'   br_magenta  '#DDB6F5'
  cyan         '#56C8D8'   br_cyan     '#8ADDE8'
  white        '#C4CCD8'   br_white    '#F2F5FA'
)

_PAL_LIGHT+=(
  bold         '#0F141C'
  cursor       $_PAL_LIGHT[sym]
  cursor_text  $_PAL_LIGHT[bg]
  sel_bg       '#C9D8EC'
  sel_fg       '#0F141C'

  black        $_PAL_LIGHT[fg]     br_black    $_PAL_LIGHT[meta]
  red          $_PAL_LIGHT[alert]  br_red      '#C8302A'
  green        '#2F7A34'   br_green    '#1F7A2A'
  yellow       $_PAL_LIGHT[dir]    br_yellow   '#8C6200'
  blue         $_PAL_LIGHT[git]    br_blue     '#2367C2'
  magenta      '#8A3DA3'   br_magenta  '#9446B0'
  cyan         '#00727F'   br_cyan     '#007786'
  white        '#DAD3C4'   br_white    '#FFFFFF'
)

# --- Tools (fzf, autosuggestions, delta — applied in 15-theme.zsh) --
#   ghost        autosuggestion text — faint on purpose, decorative
#   hl_sel       fzf matched letters on the highlighted row (sel_bg);
#                light mode needs a darker gold to stay readable there
#   diff_add/del           delta: background of added / removed lines
#   diff_add/del_emph      delta: the exact words that changed
# fzf's other colors and delta's line numbers reuse roles above.

_PAL_DARK+=(
  ghost          '#5E6E8A'
  hl_sel         $_PAL_DARK[dir]
  diff_add       '#1E3B33'   diff_add_emph  '#2A5845'
  diff_del       '#3E2433'   diff_del_emph  '#5E2E3D'
)

_PAL_LIGHT+=(
  ghost          '#8F897D'
  hl_sel         '#735000'
  diff_add       '#DDEBD3'   diff_add_emph  '#BFDCB0'
  diff_del       '#F5DAD3'   diff_del_emph  '#EBBAB0'
)
