#!/usr/bin/env bash
# Dotfiles bootstrap script
# Complete setup for a new machine or fresh install

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_section() { echo -e "\n${BLUE}▸${NC} $1\n"; }
log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

main() {
	log_section "Bootstrapping dotfiles setup"

	# 1. Install command-line tools
	if ! command -v git >/dev/null 2>&1; then
		log_warn "Installing Xcode Command Line Tools..."
		xcode-select --install
		log_info "Please re-run this script after installation completes"
		exit 0
	fi

	# 2. Install Homebrew if not present
	if ! command -v brew >/dev/null 2>&1; then
		log_warn "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	# 3. Install packages from Brewfile if it exists
	if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
		log_section "Installing packages from Brewfile"
		brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock
	fi

	# 4. Install Oh My Zsh if not present
	if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
		log_section "Installing Oh My Zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	fi

	# 5. Install Powerlevel10k theme
	if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
		log_section "Installing Powerlevel10k theme"
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
			"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
	fi

	# 6. Install OMZ plugins
	log_section "Installing Oh My Zsh plugins"

	# zsh-autosuggestions
	if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
		git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
			"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
	fi

	# fzf-tab
	if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab" ]]; then
		git clone --depth=1 https://github.com/Aloxaf/fzf-tab \
			"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
	fi

	# 7. Run the install script to create symlinks
	log_section "Creating symlinks"
	"$DOTFILES_DIR/install.sh"

	# 8. Set macOS defaults if on macOS
	if [[ "$OSTYPE" == "darwin"* && -f "$DOTFILES_DIR/macos/macos-defaults.sh" ]]; then
		log_section "Applying macOS defaults"
		log_warn "This will modify system settings. Continue? (y/N)"
		read -r response
		if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
			bash "$DOTFILES_DIR/macos/macos-defaults.sh"
		fi
	fi

	log_section "Bootstrap complete!"
	log_info "Please restart your terminal or run: source ~/.zshrc"
}

main "$@"
