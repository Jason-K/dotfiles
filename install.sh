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

# Setup dnscrypt-proxy
setup_dnscrypt_proxy() {
  local dnscrypt_binary="${HOME}/bin/dnscrypt_proxy/dnscrypt-proxy"
  local dnscrypt_config_src="$DOTFILES_DIR/dnscrypt-proxy/dnscrypt-proxy.toml"
  local dnscrypt_config_dir="${HOME}/bin/dnscrypt_proxy"
  local launch_daemon="/Library/LaunchDaemons/dnscrypt-proxy.plist"

  # Check if dnscrypt-proxy binary exists
  if [[ ! -f "$dnscrypt_binary" ]]; then
    log_warn "dnscrypt-proxy binary not found at $dnscrypt_binary"
    log_warn "Install it with: brew install dnscrypt-proxy2"
    return 0
  fi

  # Check if dnscrypt-proxy config exists in dotfiles
  if [[ ! -f "$dnscrypt_config_src" ]]; then
    log_warn "dnscrypt-proxy config not found at $dnscrypt_config_src"
    return 0
  fi

  log_info "Setting up dnscrypt-proxy..."

  # Ensure config directory exists
  mkdir -p "$dnscrypt_config_dir"

  # Copy config files to the bin directory for reference
  cp "$dnscrypt_config_src" "$dnscrypt_config_dir/dnscrypt-proxy.toml"
  log_info "Copied dnscrypt-proxy config to $dnscrypt_config_dir"

  # Copy supporting directories if they exist
  for dir in settings sources logs; do
    src="$DOTFILES_DIR/dnscrypt-proxy/$dir"
    if [[ -d "$src" ]]; then
      cp -r "$src" "$dnscrypt_config_dir/" 2>/dev/null || true
    fi
  done

  # Create or update the launch daemon plist
  if [[ ! -f "$launch_daemon" ]]; then
    log_info "Creating launch daemon for dnscrypt-proxy..."
    cat > /tmp/dnscrypt-proxy.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>dnscrypt-proxy</string>
	<key>ProgramArguments</key>
	<array>
		<string>$dnscrypt_binary</string>
		<string>-config</string>
		<string>$DOTFILES_DIR/dnscrypt-proxy/dnscrypt-proxy.toml</string>
	</array>
	<key>RunAtLoad</key>
	<false/>
	<key>SessionCreate</key>
	<false/>
	<key>StandardErrorPath</key>
	<string>/var/log/dnscrypt-proxy.err.log</string>
	<key>StandardOutPath</key>
	<string>/var/log/dnscrypt-proxy.out.log</string>
	<key>WorkingDirectory</key>
	<string>$DOTFILES_DIR/dnscrypt-proxy</string>
</dict>
</plist>
PLIST
    sudo cp /tmp/dnscrypt-proxy.plist "$launch_daemon"
    log_info "Created $launch_daemon"
  else
    log_info "Launch daemon already exists at $launch_daemon"
  fi

  # Load and start the service
  log_info "Loading dnscrypt-proxy service..."
  sudo launchctl unload "$launch_daemon" 2>/dev/null || true
  sudo launchctl load "$launch_daemon"
  log_info "dnscrypt-proxy service loaded"
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

  # Setup dnscrypt-proxy
  setup_dnscrypt_proxy

  log_info "Dotfiles installation complete!"
  log_warn "Run 'source ~/.zshrc' or open a new terminal to apply changes"
}

main "$@"
