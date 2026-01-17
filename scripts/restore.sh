#!/usr/bin/env bash
# restore.sh - Interactive tiered restoration system for dotfiles
# Supports selective restoration, preview mode, and safety backups

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_ROOT="$DOTFILES_DIR/backups"
STATE_FILE="$HOME/.dotfiles-backup-state"

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}▸${NC} $1\n"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_prompt() {
    echo -e "${CYAN}›${NC} $1"
}

# ============================================================================
# BACKUP MANAGEMENT
# ============================================================================

list_backups() {
    local backups=($(ls -1t "$BACKUP_ROOT" 2>/dev/null | grep -v "^latest$" | grep "^[0-9]" || true))

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_error "No backups found in $BACKUP_ROOT"
        return 1
    fi

    log_section "Available Backups"

    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local backup_path="$BACKUP_ROOT/$backup"
        local backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
        local backup_date=$(echo "$backup" | sed 's/_/ at /' | sed 's/\./-/g')

        printf "  ${CYAN}%2d${NC}. %s  ${YELLOW}(%s)${NC}\n" $((i+1)) "$backup_date" "$backup_size"
    done

    echo ""
}

get_backup_path() {
    local backup_choice="$1"
    local backups=($(ls -1t "$BACKUP_ROOT" 2>/dev/null | grep -E "^[0-9]{4}\.[0-9]{2}\.[0-9]_" || true))

    if [[ "$backup_choice" == "latest" ]]; then
        if [[ ${#backups[@]} -eq 0 ]]; then
            log_error "No backups found"
            return 1
        fi
        echo "$BACKUP_ROOT/${backups[0]}"
    elif [[ "$backup_choice" =~ ^[0-9]+$ ]]; then
        local index=$((backup_choice - 1))
        if [[ $index -ge 0 && $index -lt ${#backups[@]} ]]; then
            echo "$BACKUP_ROOT/${backups[$index]}"
        else
            log_error "Invalid backup number: $backup_choice"
            return 1
        fi
    else
        # Assume it's a timestamp
        local backup_path="$BACKUP_ROOT/$backup_choice"
        if [[ -d "$backup_path" ]]; then
            echo "$backup_path"
        else
            log_error "Backup not found: $backup_path"
            return 1
        fi
    fi
}

create_safety_backup() {
    local files=("$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        return 0
    fi

    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local safety_backup_dir="$BACKUP_ROOT/safety-backup-$timestamp"

    log_info "Creating safety backup at $safety_backup_dir"

    mkdir -p "$safety_backup_dir"

    for file in "${files[@]}"; do
        if [[ -e "$file" && ! -L "$file" ]]; then
            local backup_path="$safety_backup_dir/$(basename "$file").backup"
            cp -R "$file" "$backup_path"
            log_info "Backed up: $file"
        fi
    done
}

# ============================================================================
# RESTORE FUNCTIONS
# ============================================================================

parse_args() {
    BACKUP_CHOICE=""
    INTERACTIVE=1
    PREVIEW_MODE=0
    TIER="full"
    LIST_ONLY=0

    while [[ $# -gt 0 ]]; do
        case $1 in
            --backup)
                BACKUP_CHOICE="$2"
                shift 2
                ;;
            --essential)
                TIER="essential"
                shift
                ;;
            --apps)
                TIER="apps"
                shift
                ;;
            --full)
                TIER="full"
                shift
                ;;
            --non-interactive)
                INTERACTIVE=0
                shift
                ;;
            --preview)
                PREVIEW_MODE=1
                shift
                ;;
            --list)
                LIST_ONLY=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
restore.sh - Interactive tiered restoration system for dotfiles

USAGE:
    ./scripts/restore.sh [OPTIONS]

OPTIONS:
    --backup <timestamp|number|latest>  Specific backup to restore (default: latest)
    --essential                         Restore essential configs only
    --apps                              Restore essential + app preferences
    --full                              Restore everything (default)
    --non-interactive                   Skip all prompts (use with --tier)
    --preview                           Show what would be restored (dry-run)
    --list                              List available backups
    -h, --help                          Show this help message

EXAMPLES:
    ./scripts/restore.sh                           # Interactive restore from latest
    ./scripts/restore.sh --list                    # Show available backups
    ./scripts/restore.sh --backup 3                # Restore backup #3
    ./scripts/restore.sh --essential               # Quick essential restore
    ./scripts/restore.sh --preview                 # Preview what would be restored

TIERS:
    essential    Shell configs, git, SSH/GPG keys
    apps         Essential + application preferences
    full         Everything including optional data

INTERACTIVE MODE:
In interactive mode (default), you'll be prompted to select:
    1. Which backup to restore
    2. Which tiers to restore (essential, apps, system, optional)
    3. Confirmation before making changes
EOF
}

preview_restore() {
    local backup_path="$1"
    local tier="$2"

    log_section "Restore Preview"

    log_info "Backup: $backup_path"
    log_info "Tier: $tier"
    log_info "Mode: DRY RUN (no files will be changed)"
    echo ""

    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup not found: $backup_path"
        return 1
    fi

    log_info "Files that would be restored:"
    echo ""

    # Show what would be restored
    find "$backup_path" -maxdepth 3 -type f 2>/dev/null | head -20 | while read -r file; do
        local rel_path="${file#$backup_path/}"
        local size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "  • $rel_path  ($size)"
    done

    local file_count=$(find "$backup_path" -type f 2>/dev/null | wc -l | tr -d ' ')
    local total_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)

    echo ""
    log_info "Total: $file_count files, $total_size"
}

# Added: Install apps from backup inventory
install_apps() {
    local backup_path="$1"
    local inventory_dir="$backup_path/inventory"
    local brewfile="$inventory_dir/Brewfile"

    if [[ ! -f "$brewfile" ]]; then
        log_debug "No Brewfile found in backup inventory"
        return 0
    fi

    log_section "App Restoration"
    log_info "Found Brewfile in backup: $brewfile"
    log_warn "Do you want to reinstall applications/packages from this backup? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            log_warn "Homebrew not found. Installing Homebrew..."
             /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        log_info "Installing packages from Brewfile..."
        brew bundle install --file="$brewfile" --no-lock
        log_info "App restoration complete"
    else
        log_info "Skipping app restoration"
    fi
}

perform_restore() {
    log_section "Restoring Settings via Chezmoi"
    
    # 1. Initialize/Apply Chezmoi
    if command -v chezmoi >/dev/null 2>&1; then
        log_info "Applying Chezmoi state..."
        chezmoi apply
    else
        log_error "Chezmoi not found. Installing via brew..."
        if command -v brew >/dev/null 2>&1; then
            brew install chezmoi
            log_info "Applying Chezmoi state..."
            chezmoi apply
        else
            log_error "Homebrew not found. Cannot install chezmoi."
            exit 1
        fi
    fi
    
    # 2. Install Apps
    local brewfile="$DOTFILES_DIR/brew/Brewfile"
    if [[ -f "$brewfile" ]]; then
       log_section "Restoring Applications (Homebrew)"
       log_warn "This will run 'brew bundle install'. Continue? (y/N)"
       read -r response
       if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
          brew bundle install --file="$brewfile" --no-lock
       fi
    fi

    log_section "Post-Restore Steps"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Restart affected applications (iTerm, Hammerspoon, Karabiner, etc.)"
    echo "3. If you have custom secrets, ensure they are in ~/.zsh_secrets"
}

interactive_restore() {
    log_section "Dotfiles Restore (Chezmoi)"
    echo "This will:"
    echo "1. Apply settings from $DOTFILES_DIR using Chezmoi"
    echo "2. Install applications from Homebrew Brewfile"
    echo ""
    log_warn "Continue? (y/N)"
    read -r confirm
    
    if [[ "$confirm" =~ ^[yY] ]]; then
        perform_restore
    else
        log_info "Restore cancelled"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    parse_args "$@"

    # List only mode
    if [[ $LIST_ONLY -eq 1 ]]; then
        list_backups
        exit $?
    fi

    # Interactive mode
    if [[ $INTERACTIVE -eq 1 ]]; then
        interactive_restore
        exit $?
    fi

    # Non-interactive mode
    local backup_choice="${BACKUP_CHOICE:-latest}"
    local backup_path=$(get_backup_path "$backup_choice")

    if [[ -z "$backup_path" ]]; then
        log_error "Failed to locate backup: $backup_choice"
        exit 1
    fi

    perform_restore "$backup_path" "$TIER"
}

main "$@"
