#!/usr/bin/env bash
# scripts/setup-dnscrypt.sh
# Setup script for dnscrypt-proxy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

main() {
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

  # Copy config files
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
    # Warning: Using sudo inside script
    sudo cat > /tmp/dnscrypt-proxy.plist << PLIST
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

main "$@"
