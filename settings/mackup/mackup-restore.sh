#!/bin/bash
# mackup-restore.sh - Restore from a timestamped backup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUPS_DIR="$SCRIPT_DIR/backups"

# List available backups
echo "Available backups:"
ls -1d "$BACKUPS_DIR"/*/ 2>/dev/null | xargs -n1 basename | sort -r || {
    echo "No backups found in $BACKUPS_DIR"
    exit 1
}

echo ""
echo "Enter the backup timestamp to restore from (e.g., 2025.12.24_10.44.40):"
read -r TIMESTAMP

BACKUP_PATH="$BACKUPS_DIR/$TIMESTAMP"

if [ ! -d "$BACKUP_PATH" ]; then
    echo "❌ Backup not found: $BACKUP_PATH"
    exit 1
fi

# Create temporary config file in home directory
TEMP_CONFIG="$HOME/.mackup-restore-$TIMESTAMP.cfg"
trap "rm -f $TEMP_CONFIG" EXIT

cat > "$TEMP_CONFIG" << EOF
[storage]
engine = file_system
path = $BACKUP_PATH
directory = .

EOF

echo "🔄 Restoring from: $BACKUP_PATH"
echo "Using temporary config: $TEMP_CONFIG"

# Run mackup restore with the temporary config
mackup -c "$TEMP_CONFIG" restore "$@"

echo "✅ Restore complete from: $BACKUP_PATH"
