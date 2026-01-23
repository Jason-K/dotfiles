#!/usr/bin/env bash
# brew-reconcile.sh - Interactive reconciliation of Brewfile with installed packages
# Detects packages present in Brewfile but missing from system (uninstalled via other means)

set -e

BREWFILE="$HOME/dotfiles/brew/Brewfile"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ ! -f "$BREWFILE" ]]; then
    echo -e "${RED}Error: Brewfile not found at $BREWFILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking for uninstalled packages in Brewfile...${NC}"

# Check for missing dependencies
# brew bundle check returns failure if anything is missing, which is what we want to catch
if brew bundle check --file="$BREWFILE" --verbose >/dev/null 2>&1; then
    echo -e "${GREEN}All Brewfile packages are installed.${NC}"
    exit 0
fi

# Capture missing packages
# Output format usually: "cask google-chrome" or "formula wget"
missing_entries=$(brew bundle check --file="$BREWFILE" --verbose 2>&1 | grep -E "^(cask|formula|tap|mas)" || true)

if [[ -z "$missing_entries" ]]; then
    echo -e "${GREEN}No missing packages detected.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found packages in Brewfile that are NOT installed:${NC}"
echo "$missing_entries"
echo ""

# Process each missing entry
IFS=$'\n'
for line in $missing_entries; do
    type=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
    
    # Check if we should ignore this (sometimes check reports weird things)
    if [[ -z "$name" ]]; then continue; fi

    echo -ne "❓ Package ${RED}${name}${NC} is missing. Did you uninstall this intentionally? (y = remove from Brewfile, n = reinstall) [y/N] "
    read -r response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${GREEN}Removing ${name} from Brewfile...${NC}"
        # Use simple grep/sed sequence to safely remove the line
        # Match "cask 'name'" or 'cask "name"' or just 'cask name' depending on Brewfile format
        # typically Brewfile uses: cask "name"
        
        # Helper to escape special chars for sed
        escaped_name=$(echo "$name" | sed 's/[\/&]/\\&/g')
        
        # Update the Brewfile
        # This regex tries to match: type "name" OR type 'name'
        sed -i '' "/^${type} [\"']${escaped_name}[\"']/d" "$BREWFILE"
        
        echo "   Removed."
    else
        echo "   Kept in Brewfile (will be reinstalled)."
    fi
done

echo -e "${GREEN}Reconciliation complete.${NC}"
