# dotfiles

Zsh configuration. Prompt: Powerlevel10k, two-line framed, path + git only.

## Layout

| Path | What it does |
|---|---|
| `.zshrc` | Thin loader. Oh My Zsh + plugins, then sources the modules below. |
| `zsh/10-env.zsh` | PATH, history (100k entries, timestamped, shared across terminals), shell options. |
| `zsh/15-theme.zsh` | Follows macOS light/dark. Loads before the prompt so colors are set at init. |
| `zsh/20-tools.zsh` | fzf, zoxide, direnv, bat integration. |
| `zsh/25-completion.zsh` | Tab-completion behavior: menu select, case-insensitive, grouped. |
| `zsh/30-aliases.zsh` | Listing, navigation, JSON/API, Claude Code shortcuts. |
| `zsh/40-git.zsh` | Git and GitHub CLI aliases + workflow functions. |
| `zsh/50-functions.zsh` | Task helpers: fuzzy find, notes, API, worktrees. |
| `zsh/60-guardrails.zsh` | Confirmation gates on destructive git/rm operations. |
| `zsh/70-keys.zsh` | Keybindings. Loads last so plugin widgets exist. |
| `.p10k.zsh` | Prompt definition. |
| `.gitconfig` | Git settings, delta pager. |

Modules load in numeric order. To disable one, rename it without the `.zsh`
extension. To add your own, drop in a new numbered file.

## Machine-local settings

Anything secret or machine-specific goes in `~/.zshrc.local`, which is
gitignored and sourced last:

```sh
export CLICKUP_TOKEN="pk_..."
```

## Theme

Everything follows the macOS appearance setting: the prompt palette, iTerm2's
background and ANSI colors, `bat`, `delta`, and `fzf`. Switching macOS between
light and dark switches all of them, within 5 seconds at worst.

```
theme          # current mode
theme dark     # pin to dark
theme light    # pin to light
theme auto     # go back to following macOS
```

Detection is cheap. Asking macOS directly costs ~15ms, so the per-prompt check
first looks at the modification timestamp of the preferences file — a syscall
with no process launch — and only asks macOS when that timestamp moves. A
5-second poll covers the case where macOS batches the write and the timestamp
lags behind the actual setting.

Prompt colors are 256-color terminal indices in the 16–255 range, which are
fixed RGB values rather than palette slots. That means they render identically
regardless of which color scheme iTerm2 has loaded, so the two layers can't
fight each other.

## Command reference

Run `cheat` in any shell.

## Guardrails

These wrap `git` and `rm` as shell functions. Shell functions are **not**
inherited by scripts or subprocesses, so Claude Code, CI, make, and npm are
unaffected — only what you type interactively is gated.

| Command | Gate |
|---|---|
| `git push --force` | Type the branch name. Shows commits on the remote you don't have. |
| `git reset --hard` | Type `reset`. Shows how many files would be discarded. |
| `git clean -f` | Type `clean`. Lists exactly what would be deleted. |
| `git filter-branch` / `filter-repo` | Type `I HAVE A BACKUP`. Explains the working-tree deletion risk. |
| `git gc --prune` | Type `no recovery needed`. This is the point of no return. |
| `git branch -D` | y/N. Suggests `-d` instead. |
| `git rebase -i` / `--onto` | y/N. |
| `git checkout -f` | y/N. |
| `rm -rf` | Type `delete`. Hard-refuses on `/`, `$HOME`, `/System`, `/usr`, `/etc`, `/opt`, `/Applications`. |

Bypass any gate for a single command with `command git ...` or `command rm ...`.

Use `trash <path>` instead of `rm` when you want recoverable deletion.

## Install on a new machine

```sh
git clone <this-repo> ~/.dotfiles && ~/.dotfiles/install.sh
```

Then set iTerm2's font to **MesloLGS Nerd Font** and run `exec zsh`.
