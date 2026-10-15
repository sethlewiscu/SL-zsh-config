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
