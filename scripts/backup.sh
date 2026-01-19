#!/usr/bin/env bash
# backup.sh - Intelligent tiered backup system for dotfiles
# Supports change detection, scheduled backups, and dry-run mode


# Ensure Homebrew and local binaries are in PATH (crucial for cron/launchd)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

set -euo pipefail


# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_ROOT="$DOTFILES_DIR/backups"
STATE_FILE="$HOME/.dotfiles-backup-state"
LOG_DIR="$DOTFILES_DIR/logs"

# Ensure directories exist
mkdir -p "$BACKUP_ROOT" "$LOG_DIR"

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}✓${NC} $1"
}

log_section() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') ${BLUE}▸${NC} $1\n"
}


log_warn() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${RED}✗${NC} $1"
}


log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${BLUE}┃${NC} $1" >&2
    fi
}


# ============================================================================
# STATE MANAGEMENT
# ============================================================================

init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << EOF
# Dotfiles Backup State
# Auto-generated - do not edit manually

last_daily_backup=never
last_weekly_backup=never
last_manual_backup=never
last_essential_backup=never
last_apps_backup=never
last_full_backup=never
backup_count_essential=0
backup_count_apps=0
backup_count_full=0
EOF
        chmod 600 "$STATE_FILE"
    fi
}

get_state() {
    local key="$1"
    if [[ -f "$STATE_FILE" ]]; then
        grep "^${key}=" "$STATE_FILE" | cut -d'=' -f2- || echo "never"
    else
        echo "never"
    fi
}

set_state() {
    local key="$1"
    local value="$2"
    init_state

    # Update or add the key
    if grep -q "^${key}=" "$STATE_FILE"; then
        # Update existing key
        local temp_file="${STATE_FILE}.tmp"
        sed "s/^${key}=.*/${key}=${value}/" "$STATE_FILE" > "$temp_file"
        mv "$temp_file" "$STATE_FILE"
    else
        # Add new key
        echo "${key}=${value}" >> "$STATE_FILE"
    fi
}

increment_count() {
    local key="$1"
    local current_count=$(get_state "$key")
    local new_count=$((current_count + 1))
    set_state "$key" "$new_count"
    echo "$new_count"
}

# ============================================================================
# TIME UTILITIES
# ============================================================================

get_timestamp() {
    date +"%Y.%m.%d_%H.%M.%S"
}

hours_since_backup() {
    local last_backup="$1"

    if [[ "$last_backup" == "never" ]]; then
        echo 999999
        return
    fi

    # Parse timestamp (format: YYYY.MM.DD_HH.MM.SS)
    local backup_date=$(echo "$last_backup" | sed 's/_/ /' | sed 's/\./-/g')
    backup_date="${backup_date//./-}"
    backup_date="${backup_date/_/ }"

    if command -v date >/dev/null 2>&1; then
        local backup_seconds=$(date -j -f "%Y-%m-%d %H:%M:%S" "$backup_date" +"%s" 2>/dev/null || echo "0")
        local current_seconds=$(date +"%s")
        local seconds_diff=$((current_seconds - backup_seconds))
        echo $((seconds_diff / 3600))
    else
        echo 999999
    fi
}

should_run_backup() {
    local tier="$1"
    local threshold_hours="$2"
    local last_backup

    case "$tier" in
        essential)
            last_backup=$(get_state "last_essential_backup")
            ;;
        apps)
            last_backup=$(get_state "last_apps_backup")
            ;;
        full)
            last_backup=$(get_state "last_full_backup")
            ;;
        *)
            log_error "Unknown tier: $tier"
            return 1
            ;;
    esac

    local hours_since=$(hours_since_backup "$last_backup")
    log_debug "Hours since last ${tier} backup: $hours_since (threshold: $threshold_hours)"

    [[ $hours_since -ge $threshold_hours ]]
}

# ============================================================================
# BACKUP FUNCTIONS
# ============================================================================

parse_args() {
    TIER=""
    DRY_RUN=0
    FORCE=0
    CHECK_SCHEDULE=0
    QUIET=0

    while [[ $# -gt 0 ]]; do
        case $1 in
            --tier)
                TIER="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --force)
                FORCE=1
                shift
                ;;
            --check-schedule)
                CHECK_SCHEDULE=1
                shift
                ;;
            --quiet)
                QUIET=1
                shift
                ;;
            --full)
                TIER="full"
                shift
                ;;
            --essential)
                TIER="essential"
                shift
                ;;
            --apps)
                TIER="apps"
                shift
                ;;
            --debug)
                DEBUG=1
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

    # Default tier is essential
    if [[ -z "$TIER" ]]; then
        TIER="essential"
    fi
}

show_help() {
    cat << EOF
backup.sh - Intelligent tiered backup system for dotfiles

USAGE:
    ./scripts/backup.sh [OPTIONS]

OPTIONS:
    --tier <tier>           Backup tier: essential, apps, full (default: essential)
    --essential             Alias for --tier essential
    --apps                  Alias for --tier apps
    --full                  Alias for --tier full
    --dry-run               Show what would be backed up without doing it
    --force                 Force backup even if no changes detected
    --check-schedule        Check if backup is due (used by launchd)
    --quiet                 Suppress output (except errors)
    --debug                 Enable debug logging
    -h, --help              Show this help message

EXAMPLES:
    ./scripts/backup.sh                    # Quick essential backup
    ./scripts/backup.sh --full             # Full backup of everything
    ./scripts/backup.sh --tier apps        # Backup app settings only
    ./scripts/backup.sh --dry-run          # Preview what would be backed up

TIERS:
    essential    Shell configs, git, SSH/GPG keys (~1-5 MB, ~30s)
    apps         Application preferences (~10-50 MB, ~2-5 min)
    full         Everything including optional data (~100 MB - 2 GB, ~5-15 min)
EOF
}

detect_changes() {
    local tier="$1"
    local last_backup

    case "$tier" in
        essential)
            last_backup=$(get_state "last_essential_backup")
            ;;
        apps)
            last_backup=$(get_state "last_apps_backup")
            ;;
        full)
            last_backup=$(get_state "last_full_backup")
            ;;
    esac

    if [[ "$last_backup" == "never" ]]; then
        log_debug "No previous backup found - will create initial backup"
        return 0  # Always backup if no previous backup
    fi

    # Check if files have changed since last backup
    # This is a simple implementation - could be enhanced with file hashing
    local backup_path="$BACKUP_ROOT/$last_backup"

    if [[ ! -d "$backup_path" ]]; then
        log_debug "Previous backup not found at $backup_path"
        return 0
    fi

    # For now, always run backup if forced
    if [[ $FORCE -eq 1 ]]; then
        log_debug "Force mode enabled - will backup regardless of changes"
        return 0
    fi

    # TODO: Implement proper change detection using file modification times
    # For now, we'll always backup
    return 0
}

create_backup() {
    local tier="$1"
    
    # --- 1. Settings Backup (Chezmoi) ---
    log_section "Backing up settings via Chezmoi"
    
    # Ensure we are in the dotfiles directory
    if cd "$DOTFILES_DIR"; then
        log_info "Adding changes to Chezmoi..."
        
        # Pull latest changes from home directory (auto-sync local edits)
        log_info "Syncing local edits..."
        chezmoi re-add
        
        # Git add
        chezmoi git -- add .
        
        # Git commit (if changes exist)
        if ! chezmoi git -- diff --quiet --cached; then
            local timestamp
            timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
            chezmoi git -- commit -m "Backup $timestamp (Tier: $tier)"
            log_info "✅ Created chezmoi commit: Backup $timestamp"
        else
            log_info "No settings changes to commit in Chezmoi."
        fi
    else
        log_error "Could not changes to dotfiles dir: $DOTFILES_DIR"
    fi

    # --- 2. System Inventory Backup (Brewfile, etc.) ---
    # We still want to capture what apps are installed, even if Chezmoi tracks settings.
    log_section "Capturing System Inventory"
    
    local timestamp=$(get_timestamp)
    local backup_path="$BACKUP_ROOT/$timestamp"
    
    if [[ $DRY_RUN -eq 1 ]]; then
         log_warn "DRY RUN - Would capture inventory to: $backup_path"
         return 0
    fi
    
    log_info "Creating inventory backup at: $backup_path"
    capture_inventory "$tier" "$backup_path"
    
    # Update latest symlink
    ln -sfn "$timestamp" "$BACKUP_ROOT/latest"
    
    # Update state
    set_state "last_${tier}_backup" "$timestamp"
    local new_count=$(increment_count "backup_count_${tier}")
    
    # Cleanup old inventory backups
    cleanup_old_backups "$tier"
    
    return 0
}

# ============================================================================
# INVENTORY FUNCTIONS
# ============================================================================

capture_quick_inventory() {
    local inventory_dir="$1"
    local failed_sections=()

    log_debug "Capturing quick inventory (apps & packages)..."

    # Homebrew
    if brew --version >/dev/null 2>&1; then
        brew update >/dev/null 2>&1 || true
        brew bundle dump --force --file="$inventory_dir/Brewfile" 2>/dev/null || failed_sections+=("brew-bundle")
        brew leaves > "$inventory_dir/apps/brew_leaves.txt" 2>/dev/null || failed_sections+=("brew-leaves")
        brew list --cask > "$inventory_dir/apps/brew_casks.txt" 2>/dev/null || failed_sections+=("brew-casks")
        brew list > "$inventory_dir/apps/brew_formulae.txt" 2>/dev/null || failed_sections+=("brew-formulae")
    else
        failed_sections+=("homebrew")
    fi

    # App Store
    if command -v mas >/dev/null 2>&1; then
        mas list > "$inventory_dir/apps/mas_apps.txt" 2>/dev/null || failed_sections+=("mas")
    else
        log_debug "mas not installed - skipping App Store inventory"
    fi

    # Applications directory
    ls -1 /Applications > "$inventory_dir/apps/Applications_root.txt" 2>/dev/null || failed_sections+=("apps-root")
    ls -1 "$HOME/Applications" > "$inventory_dir/apps/Applications_user.txt" 2>/dev/null || true

    # Report failures
    if [[ ${#failed_sections[@]} -gt 0 ]]; then
        log_warn "Some inventory sections failed: ${failed_sections[*]}"
    fi

    log_debug "Quick inventory complete"
}

capture_detailed_inventory() {
    local inventory_dir="$1"
    local failed_sections=()

    log_debug "Capturing detailed inventory (system, dev, configs)..."

    # Login items & launch items
    osascript -e 'tell application "System Events" to get name of every login item' \
        > "$inventory_dir/system/login_items.txt" 2>/dev/null || failed_sections+=("login-items")
    launchctl list > "$inventory_dir/system/launchctl_list.txt" 2>/dev/null || failed_sections+=("launchctl")
    ls -1 ~/Library/LaunchAgents > "$inventory_dir/system/LaunchAgents_user.txt" 2>/dev/null || true
    ls -1 /Library/LaunchAgents > "$inventory_dir/system/LaunchAgents_global.txt" 2>/dev/null || true
    ls -1 /Library/LaunchDaemons > "$inventory_dir/system/LaunchDaemons_global.txt" 2>/dev/null || true
    crontab -l > "$inventory_dir/system/crontab.txt" 2>/dev/null || true

    # Shell & Git
    echo "$SHELL" > "$inventory_dir/system/shell.txt"
    zsh --version > "$inventory_dir/system/zsh_version.txt" 2>/dev/null || true
    bash --version > "$inventory_dir/system/bash_version.txt" 2>/dev/null || true
    git --version > "$inventory_dir/dev/git_version.txt" 2>/dev/null || true
    git config --global -l > "$inventory_dir/dev/git_config_global.txt" 2>/dev/null || true

    # SSH / GPG (listings only, no secrets)
    ls -l ~/.ssh > "$inventory_dir/dev/ssh_keys_listing.txt" 2>/dev/null || true
    gpg --version > "$inventory_dir/dev/gpg_version.txt" 2>/dev/null || true
    gpg --list-keys > "$inventory_dir/dev/gpg_public_keys.txt" 2>/dev/null || true

    # Python
    { pyenv versions 2>/dev/null || asdf list python 2>/dev/null || true; } > "$inventory_dir/dev/python_versions.txt" 2>/dev/null || true
    python3 --version > "$inventory_dir/dev/python_default.txt" 2>/dev/null || true
    pipx list > "$inventory_dir/dev/pipx_list.txt" 2>/dev/null || true
    pip3 list --format=freeze > "$inventory_dir/dev/pip3_freeze.txt" 2>/dev/null || true

    # Node
    { nvm ls 2>/dev/null || fnm list 2>/dev/null || volta list 2>/dev/null || asdf list nodejs 2>/dev/null || true; } \
        > "$inventory_dir/dev/node_versions.txt" 2>/dev/null || true
    npm -g list --depth=0 > "$inventory_dir/dev/npm_global.txt" 2>/dev/null || true
    pnpm -g list --depth=0 > "$inventory_dir/dev/pnpm_global.txt" 2>/dev/null || true
    corepack --version > "$inventory_dir/dev/corepack.txt" 2>/dev/null || true

    # Ruby / Go
    { rbenv versions 2>/dev/null || asdf list ruby 2>/dev/null || true; } > "$inventory_dir/dev/ruby_versions.txt" 2>/dev/null || true
    go version > "$inventory_dir/dev/go_version.txt" 2>/dev/null || true
    ls -1 ~/go/bin > "$inventory_dir/dev/go_bin_listing.txt" 2>/dev/null || true

    # Editors & extensions
    command -v code >/dev/null 2>&1 && code --list-extensions > "$inventory_dir/dev/vscode_extensions.txt" 2>/dev/null || true
    command -v idea >/dev/null 2>&1 && echo "[JetBrains installed]" > "$inventory_dir/dev/jetbrains.txt" 2>/dev/null || true

    # Key app config paths (non-secret)
    for p in \
        "$HOME/.hammerspoon" \
        "$HOME/.config/karabiner" \
        "$HOME/Library/Application Support/Keyboard Maestro" \
        "$HOME/Library/Application Support/Noodlesoft/Hazel" \
        "$HOME/Library/Preferences/org.hammerspoon.Hammerspoon.plist" \
        "$HOME/Library/Preferences/org.pqrs.Karabiner-Elements.plist"
    do
        [ -e "$p" ] && echo "$p" >> "$inventory_dir/configs/paths_captured.txt"
    done

    # macOS Defaults snapshot
    plutil -convert xml1 ~/Library/Preferences/com.apple.finder.plist -o "$inventory_dir/configs/finder.plist" 2>/dev/null || true
    {
        defaults read -g > "$inventory_dir/configs/defaults_global.txt" 2>/dev/null || true
        defaults read com.apple.finder > "$inventory_dir/configs/defaults_finder.txt" 2>/dev/null || true
        defaults read com.apple.dock > "$inventory_dir/configs/defaults_dock.txt" 2>/dev/null || true
    }

    # Report failures
    if [[ ${#failed_sections[@]} -gt 0 ]]; then
        log_warn "Some detailed inventory sections failed: ${failed_sections[*]}"
    fi

    log_debug "Detailed inventory complete"
}

capture_inventory() {
    local tier="$1"
    local backup_path="$2"
    local inventory_dir="$backup_path/inventory"

    log_info "Capturing system inventory..."

    # Create inventory directory structure
    mkdir -p "$inventory_dir"/{apps,configs,dev,system}

    if [[ "$tier" == "essential" ]]; then
        capture_quick_inventory "$inventory_dir"
    elif [[ "$tier" == "apps" ]]; then
        capture_quick_inventory "$inventory_dir"
    elif [[ "$tier" == "full" ]]; then
        capture_quick_inventory "$inventory_dir"
        capture_detailed_inventory "$inventory_dir"
    fi

    # Create inventory summary
    local app_count=$(wc -l < "$inventory_dir/apps/brew_formulae.txt" 2>/dev/null || echo "0")
    local cask_count=$(wc -l < "$inventory_dir/apps/brew_casks.txt" 2>/dev/null || echo "0")

    log_info "Inventory captured: $app_count formulae, $cask_count casks"
}

cleanup_old_backups() {
    local tier="$1"
    local keep_count=10

    # Get list of backups for this tier, sorted by date (oldest first)
    local backups=($(ls -1t "$BACKUP_ROOT" | grep -E "^[0-9]{4}\.[0-9]{2}\.[0-9]_" || true))

    if [[ ${#backups[@]} -le $keep_count ]]; then
        log_debug "Only ${#backups[@]} backups found (keeping $keep_count)"
        return 0
    fi

    log_info "Cleaning up old backups (keeping last $keep_count)..."

    # Remove old backups
    local to_remove=$(( ${#backups[@]} - keep_count ))
    for (( i=0; i<$to_remove; i++ )); do
        local old_backup="${backups[$i]}"
        log_debug "Removing old backup: $old_backup"
        rm -rf "$BACKUP_ROOT/$old_backup"
    done

    log_info "Removed $to_remove old backup(s)"
}

show_status() {
    log_section "Backup Status"

    echo "Last backups:"
    echo "  Essential:  $(get_state 'last_essential_backup')"
    echo "  Apps:       $(get_state 'last_apps_backup')"
    echo "  Full:       $(get_state 'last_full_backup')"
    echo ""

    echo "Backup counts:"
    echo "  Essential:  $(get_state 'backup_count_essential')"
    echo "  Apps:       $(get_state 'backup_count_apps')"
    echo "  Full:       $(get_state 'backup_count_full')"
    echo ""

    # Show total size of backups
    if [[ -d "$BACKUP_ROOT" ]]; then
        local total_size=$(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)
        local backup_count=$(ls -1 "$BACKUP_ROOT" 2>/dev/null | grep -E "^[0-9]{4}\.[0-9]{2}\.[0-9]_" | wc -l | tr -d ' ')
        echo "Total storage: $total_size"
        echo "Total backups: $backup_count"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    parse_args "$@"

    # Initialize state file
    init_state

    # Check schedule mode (for launchd)
    if [[ $CHECK_SCHEDULE -eq 1 ]]; then
        local threshold=20
        case "$TIER" in
            essential) threshold=20 ;;   # 20 hours
            apps) threshold=144 ;;        # 6 days (144 hours)
            full) threshold=144 ;;        # 6 days
        esac

        if should_run_backup "$TIER" "$threshold"; then
            log_debug "Backup due for tier: $TIER"
            create_backup "$TIER"
            exit $?
        else
            log_debug "Backup not due for tier: $TIER (last backup: $(get_state "last_${TIER}_backup"))"
            exit 0
        fi
    fi

    # Show status if requested
    if [[ "${SHOW_STATUS:-0}" == "1" ]]; then
        show_status
        exit 0
    fi

    # Normal backup flow
    if [[ $QUIET -eq 0 ]]; then
        log_section "Dotfiles Backup System"
        log_info "Tier: $TIER"
    fi

    # Detect changes
    if detect_changes "$TIER"; then
        create_backup "$TIER"
        local exit_code=$?

        if [[ $exit_code -eq 0 && $QUIET -eq 0 ]]; then
            log_info "✅ Backup completed successfully!"
        fi

        exit $exit_code
    else
        if [[ $QUIET -eq 0 ]]; then
            log_info "No changes detected - backup not needed"
            log_info "Use --force to backup anyway"
        fi
        exit 0
    fi
}

main "$@"
