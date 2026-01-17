#!/usr/bin/env bash
# backup-scheduler.sh - Manage automated backup scheduling via launchd
# Handles enable/disable, status checks, and launchd plist management

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_SCRIPT="$DOTFILES_DIR/scripts/backup.sh"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$DOTFILES_DIR/logs"

# Launchd agent identifiers
readonly DAILY_AGENT="com.dotfiles.backup.daily"
readonly WEEKLY_AGENT="com.dotfiles.backup.weekly"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# ============================================================================
# LOGGING
# ============================================================================

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_section() { echo -e "\n${BLUE}▸${NC} $1\n"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# ============================================================================
# PLIST GENERATION
# ============================================================================

create_daily_plist() {
    local plist_path="$LAUNCH_AGENTS_DIR/${DAILY_AGENT}.plist"

    cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${DAILY_AGENT}</string>

  <key>ProgramArguments</key>
  <array>
    <string>${BACKUP_SCRIPT}</string>
    <string>--tier</string>
    <string>essential</string>
    <string>--check-schedule</string>
    <string>--quiet</string>
  </array>

  <key>StartCalendarInterval</key>
  <array>
    <!-- 9:00 AM -->
    <dict>
      <key>Hour</key><integer>9</integer>
      <key>Minute</key><integer>0</integer>
    </dict>
    <!-- 1:00 PM -->
    <dict>
      <key>Hour</key><integer>13</integer>
      <key>Minute</key><integer>0</integer>
    </dict>
    <!-- 5:00 PM -->
    <dict>
      <key>Hour</key><integer>17</integer>
      <key>Minute</key><integer>0</integer>
    </dict>
  </array>

  <key>WorkingDirectory</key>
  <string>${DOTFILES_DIR}</string>

  <key>StandardOutPath</key>
  <string>${LOG_DIR}/backup-daily.log</string>

  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/backup-daily.err</string>

  <key>RunAtLoad</key>
  <false/>

  <!-- Keep alive only if it crashes -->
  <key>KeepAlive</key>
  <false/>
</dict>
</plist>
EOF

    log_info "Created daily launchd plist: $plist_path"
}

create_weekly_plist() {
    local plist_path="$LAUNCH_AGENTS_DIR/${WEEKLY_AGENT}.plist"

    cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${WEEKLY_AGENT}</string>

  <key>ProgramArguments</key>
  <array>
    <string>${BACKUP_SCRIPT}</string>
    <string>--tier</string>
    <string>apps</string>
    <string>--check-schedule</string>
    <string>--quiet</string>
  </array>

  <!-- Monday at 12:30 PM -->
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>12</integer>
    <key>Minute</key><integer>30</integer>
  </dict>

  <key>WorkingDirectory</key>
  <string>${DOTFILES_DIR}</string>

  <key>StandardOutPath</key>
  <string>${LOG_DIR}/backup-weekly.log</string>

  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/backup-weekly.err</string>

  <key>RunAtLoad</key>
  <false/>

  <key>KeepAlive</key>
  <false/>
</dict>
</plist>
EOF

    log_info "Created weekly launchd plist: $plist_path"
}

# ============================================================================
# LAUNCHD MANAGEMENT
# ============================================================================

enable_scheduler() {
    log_section "Enabling Backup Scheduler"

    # Ensure LaunchAgents directory exists
    mkdir -p "$LAUNCH_AGENTS_DIR"
    mkdir -p "$LOG_DIR"

    # Create plist files
    create_daily_plist
    create_weekly_plist

    # Load agents
    log_info "Loading launchd agents..."

    launchctl load "$LAUNCH_AGENTS_DIR/${DAILY_AGENT}.plist" 2>/dev/null && \
        log_info "Daily backup agent loaded" || \
        log_warn "Daily backup agent already loaded or failed to load"

    launchctl load "$LAUNCH_AGENTS_DIR/${WEEKLY_AGENT}.plist" 2>/dev/null && \
        log_info "Weekly backup agent loaded" || \
        log_warn "Weekly backup agent already loaded or failed to load"

    echo ""
    log_info "✅ Backup scheduler enabled!"
    echo ""
    echo "Schedule:"
    echo "  • Daily (essential): 9 AM, 1 PM, 5 PM (catch-up if offline)"
    echo "  • Weekly (apps): Monday 12:30 PM (catch-up if offline)"
    echo ""
    echo "View logs:"
    echo "  tail -f $LOG_DIR/backup-daily.log"
}

disable_scheduler() {
    log_section "Disabling Backup Scheduler"

    local unloaded=0

    # Unload daily agent
    if launchctl list "$DAILY_AGENT" &>/dev/null; then
        launchctl unload "$LAUNCH_AGENTS_DIR/${DAILY_AGENT}.plist" 2>/dev/null && \
            log_info "Daily backup agent unloaded" || \
            log_warn "Failed to unload daily backup agent"
        unloaded=1
    fi

    # Unload weekly agent
    if launchctl list "$WEEKLY_AGENT" &>/dev/null; then
        launchctl unload "$LAUNCH_AGENTS_DIR/${WEEKLY_AGENT}.plist" 2>/dev/null && \
            log_info "Weekly backup agent unloaded" || \
            log_warn "Failed to unload weekly backup agent"
        unloaded=1
    fi

    if [[ $unloaded -eq 0 ]]; then
        log_info "No agents were currently running"
    fi

    echo ""
    log_info "✅ Backup scheduler disabled"
    echo ""
    echo "Note: Plist files remain in $LAUNCH_AGENTS_DIR"
    echo "      Run 'enable' to restart scheduling"
}

show_status() {
    log_section "Backup Scheduler Status"

    local daily_running=0
    local weekly_running=0

    # Check daily agent
    if launchctl list "$DAILY_AGENT" &>/dev/null; then
        log_info "Daily agent: ${GREEN}running${NC}"
        daily_running=1
    else
        log_info "Daily agent: ${YELLOW}not running${NC}"
    fi

    # Check weekly agent
    if launchctl list "$WEEKLY_AGENT" &>/dev/null; then
        log_info "Weekly agent: ${GREEN}running${NC}"
        weekly_running=1
    else
        log_info "Weekly agent: ${YELLOW}not running${NC}"
    fi

    echo ""

    # Show last backup times
    if [[ -f "$HOME/.dotfiles-backup-state" ]]; then
        echo "Last backups:"
        echo "  Essential: $(grep 'last_essential_backup=' "$HOME/.dotfiles-backup-state" 2>/dev/null | cut -d'=' -f2 || echo 'never')"
        echo "  Apps:      $(grep 'last_apps_backup=' "$HOME/.dotfiles-backup-state" 2>/dev/null | cut -d'=' -f2 || echo 'never')"
        echo "  Full:      $(grep 'last_full_backup=' "$HOME/.dotfiles-backup-state" 2>/dev/null | cut -d'=' -f2 || echo 'never')"
    fi

    echo ""

    # Show schedule
    if [[ $daily_running -eq 1 || $weekly_running -eq 1 ]]; then
        echo "Schedule:"
        echo "  • Daily checks: 9 AM, 1 PM, 5 PM (runs if >20h since last)"
        echo "  • Weekly check: Monday 12:30 PM (runs if >6 days since last)"
    fi

    echo ""

    # Show log files
    if [[ -f "$LOG_DIR/backup-daily.log" ]]; then
        echo "Recent daily log entries:"
        tail -3 "$LOG_DIR/backup-daily.log" 2>/dev/null | sed 's/^/  /' || true
    fi
}

show_logs() {
    log_section "Backup Logs"

    local log_count=0

    if [[ -f "$LOG_DIR/backup-daily.log" ]]; then
        echo "=== Daily Backup Log ==="
        tail -20 "$LOG_DIR/backup-daily.log"
        log_count=$((log_count + 1))
    fi

    if [[ -f "$LOG_DIR/backup-weekly.log" ]]; then
        echo ""
        echo "=== Weekly Backup Log ==="
        tail -20 "$LOG_DIR/backup-weekly.log"
        log_count=$((log_count + 1))
    fi

    if [[ $log_count -eq 0 ]]; then
        log_warn "No log files found"
        echo "Logs will appear at: $LOG_DIR/backup-*.log"
    fi
}

run_now() {
    log_section "Running Backup Now"

    log_info "Triggering immediate backup..."

    "$BACKUP_SCRIPT" --tier essential

    log_info "Backup complete!"
}

# ============================================================================
# HELPERS
# ============================================================================

show_help() {
    cat << EOF
backup-scheduler.sh - Manage automated backup scheduling

USAGE:
    ./scripts/backup-scheduler.sh <command>

COMMANDS:
    enable          Enable automated backup scheduling
    disable         Disable automated backup scheduling
    status          Show scheduler status and last backup times
    logs            Show recent backup logs
    run-now         Trigger an immediate backup
    help            Show this help message

SCHEDULING BEHAVIOR:
    Daily backups: Run at 9 AM, 1 PM, 5 PM if last backup was >20 hours ago
    Weekly backups: Run Monday at 12:30 PM if last backup was >6 days ago

    This "catch-up" scheduling ensures backups run even if your computer
    was off during the scheduled time.

EXAMPLES:
    ./scripts/backup-scheduler.sh enable
    ./scripts/backup-scheduler.sh status
    ./scripts/backup-scheduler.sh logs
    ./scripts/backup-scheduler.sh run-now
EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        enable)
            enable_scheduler
            ;;
        disable)
            disable_scheduler
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        run-now)
            run_now
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
