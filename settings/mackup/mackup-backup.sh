#!/bin/bash
# mackup-backup.sh - Wrapper to backup with timestamped directory

set -euo pipefail

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Generate timestamp in YYYY.MM.DD_HH.MM.SS format
TIMESTAMP=$(date +"%Y.%m.%d_%H.%M.%S")

# Create the backups directory if it doesn't exist
BACKUPS_DIR="$DOTFILES_DIR/mackup/backups"
mkdir -p "$BACKUPS_DIR"

# Create timestamped backup directory
BACKUP_PATH="$BACKUPS_DIR/$TIMESTAMP"
mkdir -p "$BACKUP_PATH"

# Create temporary config file in home directory (mackup requires this)
TEMP_CONFIG="$HOME/.mackup-timestamped-$TIMESTAMP.cfg"
trap "rm -f $TEMP_CONFIG" EXIT

cat > "$TEMP_CONFIG" << EOF
[storage]
engine = file_system
path = $BACKUP_PATH
directory = .

EOF

echo "📦 Starting mackup backup to: $BACKUP_PATH"
echo "Using temporary config: $TEMP_CONFIG"

# Run mackup with the temporary config
mackup -c "$TEMP_CONFIG" backup "$@"

echo "✅ Backup complete at: $BACKUP_PATH"
