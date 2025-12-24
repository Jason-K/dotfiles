#!/bin/bash

# DNSCrypt-Proxy Blocklist Auto-Update Script
# Automatically generates a fresh blocklist from configured sources

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/domains-blocklist.conf"
ALLOWLIST_FILE="$SETTINGS_DIR/allowed-domains.txt"
TIME_RESTRICTED_FILE="$SETTINGS_DIR/blocked-time-periods.txt"
OUTPUT_FILE="$SETTINGS_DIR/blocked-domains-generated.txt"
LOG_FILE="$HOME/dotfiles/dnscrypt-proxy/logs/blocklist-update.log"
GENERATOR_SCRIPT="$SCRIPT_DIR/generate-domains-blocklist.py"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handler
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Start update
log "========================================"
log "Starting blocklist update"
log "========================================"

# Check if Python script exists
if [[ ! -f "$GENERATOR_SCRIPT" ]]; then
    error_exit "Generator script not found: $GENERATOR_SCRIPT"
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    error_exit "Config file not found: $CONFIG_FILE"
fi

# Create a temporary output file
TEMP_OUTPUT="${OUTPUT_FILE}.tmp"

# Run the generator with progress reporting
log "Generating blocklist from configured sources..."
if python3 "$GENERATOR_SCRIPT" \
    --config "$CONFIG_FILE" \
    --allowlist "$ALLOWLIST_FILE" \
    --time-restricted "$TIME_RESTRICTED_FILE" \
    --output-file "$TEMP_OUTPUT" \
    --timeout 30 \
    --ignore-retrieval-failure \
    --progress 2>&1 | tee -a "$LOG_FILE"; then

    # Check if the generated file is not empty
    if [[ -s "$TEMP_OUTPUT" ]]; then
        # Count domains
        DOMAIN_COUNT=$(grep -c '^[^#]' "$TEMP_OUTPUT" || echo "0")

        # Sanity check - ensure we have a reasonable number of domains
        if [[ $DOMAIN_COUNT -lt 100 ]]; then
            error_exit "Generated blocklist seems too small ($DOMAIN_COUNT domains). Not replacing existing file."
        fi

        # Move the temp file to the final location
        mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
        log "SUCCESS: Blocklist updated successfully with $DOMAIN_COUNT domains"

        # Optional: Restart dnscrypt-proxy to reload the blocklist
        # Uncomment the following lines if you want automatic restart
        # if pgrep -x "dnscrypt-proxy" > /dev/null; then
        #     log "Restarting dnscrypt-proxy to apply new blocklist..."
        #     brew services restart dnscrypt-proxy 2>&1 | tee -a "$LOG_FILE"
        #     log "dnscrypt-proxy restarted"
        # fi
    else
        rm -f "$TEMP_OUTPUT"
        error_exit "Generated blocklist is empty"
    fi
else
    rm -f "$TEMP_OUTPUT"
    error_exit "Failed to generate blocklist"
fi

log "Blocklist update completed"
log "========================================"

exit 0
