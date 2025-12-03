#!/usr/bin/env bash
# Dotfiles installation script
# Safely creates symlinks from ~ to ~/dotfiles/shell/

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
SHELL_DIR="$DOTFILES_DIR/shell"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Backup existing file
backup_file() {
  local file="$1"
  local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
  if [[ -f "$file" && ! -L "$file" ]]; then
    cp "$file" "$backup"
    log_info "Backed up $file to $backup"
  fi
}

# Create symlink safely
create_symlink() {
  local source="$1"
  local target="$2"

  if [[ ! -f "$source" ]]; then
    log_error "Source file $source does not exist"
    return 1
  fi

  # If target exists and is not a symlink, back it up
  if [[ -e "$target" && ! -L "$target" ]]; then
    backup_file "$target"
    rm "$target"
  elif [[ -L "$target" ]]; then
    # Remove existing symlink
    rm "$target"
  fi

  ln -s "$source" "$target"
  log_info "Linked $target → $source"
}

main() {
  log_info "Installing dotfiles from $DOTFILES_DIR"

  # Check if dotfiles directory exists
  if [[ ! -d "$SHELL_DIR" ]]; then
    log_error "Shell directory $SHELL_DIR not found"
    exit 1
  fi

  # Shell configuration files
  create_symlink "$SHELL_DIR/.zshrc" "$HOME/.zshrc"
  create_symlink "$SHELL_DIR/.zshenv" "$HOME/.zshenv"
  create_symlink "$SHELL_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
  create_symlink "$SHELL_DIR/.zsh_secrets" "$HOME/.zsh_secrets"

  # Set secure permissions on secrets
  chmod 600 "$SHELL_DIR/.zsh_secrets"
  log_info "Set secure permissions (600) on .zsh_secrets"

  log_info "Dotfiles installation complete!"
  log_warn "Run 'source ~/.zshrc' or open a new terminal to apply changes"
}

main "$@"
