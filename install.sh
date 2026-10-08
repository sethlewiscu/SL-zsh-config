#!/usr/bin/env bash
# Bootstrap this shell config on a fresh Mac.
#   git clone <repo> ~/.dotfiles && ~/.dotfiles/install.sh
set -euo pipefail
DF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Homebrew packages"
command -v brew >/dev/null || {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}
brew install fzf eza bat fd zoxide git-delta direnv ripgrep gh jq gitleaks
brew install --cask iterm2 font-meslo-lg-nerd-font

echo "==> Oh My Zsh"
[ -d "$HOME/.oh-my-zsh" ] || \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZC="$HOME/.oh-my-zsh/custom"
clone() { [ -d "$2" ] || git clone --depth=1 "$1" "$2"; }
clone https://github.com/romkatv/powerlevel10k.git               "$ZC/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions           "$ZC/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting       "$ZC/plugins/zsh-syntax-highlighting"
clone https://github.com/zsh-users/zsh-history-substring-search  "$ZC/plugins/zsh-history-substring-search"
clone https://github.com/zsh-users/zsh-completions               "$ZC/plugins/zsh-completions"

echo "==> Git hooks (secret scan, no shadowed commands)"
git -C "$DF" config core.hooksPath .githooks

echo "==> Symlinks"
mkdir -p "$HOME/.config"
backup_and_link() {
  local src="$1" dst="$2"
  [ -L "$dst" ] && rm "$dst"
  [ -e "$dst" ] && mv "$dst" "$dst.bak.$(date +%s)"
  ln -s "$src" "$dst"
  echo "    $dst -> $src"
}
for f in .zshrc .p10k.zsh .gitconfig .zprofile; do
  [ -e "$DF/$f" ] && backup_and_link "$DF/$f" "$HOME/$f"
done
backup_and_link "$DF/zsh" "$HOME/.config/zsh"

echo "==> Done. Set iTerm2's font to 'MesloLGS Nerd Font', then: exec zsh"
