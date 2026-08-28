# dotfiles

Zsh configuration. Prompt: Powerlevel10k, two-line framed, path + git only.

## Layout

| Path | What it does |
|---|---|
| `.zshrc` | Thin loader. Oh My Zsh + plugins, then sources the modules below. |
| `zsh/10-env.zsh` | PATH, history (100k entries, timestamped, shared across terminals), shell options. |
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
