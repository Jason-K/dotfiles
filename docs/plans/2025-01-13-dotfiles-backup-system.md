---
title: Comprehensive Dotfiles Backup and Restoration System
created: 2025-01-13
last_updated: 2025-01-13
category: infrastructure
tags: [backup, restore, automation, mackup, dotfiles]
status: draft
---

# Comprehensive Dotfiles Backup and Restoration System

## Overview

Design and implement a comprehensive, tiered backup and restore system for macOS dotfiles that:
- Captures shell configs, system preferences, application settings, and user data
- Automates routine backups with catch-up scheduling for machines that are off during scheduled times
- Provides tiered restoration (essential → recommended → optional) for flexible recovery
- Integrates with existing dotfiles git repository without bloating history
- Validates backup integrity and provides clear visibility into what's being captured

## Problem Statement

Current dotfiles setup has:
- Begun backup process but never completed it
- Manual Mackup scripts exist but aren't integrated or automated
- No scheduled backups - relies on memory
- Unclear what settings are captured and what's missing
- Restoration process untested on fresh macOS install

Goals:
1. Complete backup setup covering all settings categories
2. Automate with catch-up scheduling (works even if computer is off)
3. Make restoration reliable and predictable
4. Keep git history clean while maintaining comprehensive backups

## Architecture

### Directory Structure

```
dotfiles/
├── .git/                          # Working configs (version controlled)
├── shell/                         # Tracked configs
├── hammerspoon/                   # Tracked configs
├── karabiner/                     # Tracked configs
├── settings/
│   ├── mackup/
│   │   ├── .mackup.cfg           # Tracked: Main Mackup config
│   │   ├── *.cfg                 # Tracked: App-specific configs
│   │   ├── backups/              # Git-ignored: Auto-generated backups
│   │   │   ├── latest/           # Symlink to most recent
│   │   │   ├── 2025.01.13_12.00.00/
│   │   │   └── 2025.01.12_12.00.00/
│   │   └── catalog.json          # Tracked: Backup metadata
│   ├── manual/                   # Tracked: Hand-crafted configs
│   │   ├── macos-defaults.sh
│   │   └── dock.sh
│   └── exported/                 # Tracked: Exported app settings
│       ├── raycast.json
│       └── rectangle.json
└── scripts/
    ├── backup.sh                 # Smart backup command
    ├── restore.sh                # Tiered restore
    └── backup-scheduler.sh       # launchd manager
```

### Git Strategy

**Tracked in Git:**
- Mackup configuration files (.cfg)
- Backup/restore scripts
- Exported application settings
- Catalog metadata (catalog.json)
- Manual configuration scripts

**Git-Ignored:**
- Timestamped backup directories (`backups/*/`)
- Temporary state files
- Encrypted secrets (already handled via .gitignore)

**Backup Promotion:**
- Selective commits: Promote specific backup to "golden" config when stable
- Example: After perfecting Karabiner setup, commit that backup as reference

## Backup System

### Three-Tier Strategy

**Tier 1 - Essential (Auto-daily):**
- Shell configs (.zshrc, .zshenv, .gitconfig)
- SSH/GPG keys (encrypted)
- Core dev tools (vim, tmux, default editor settings)
- Size: ~1-5 MB, Time: ~30 seconds

**Tier 2 - Recommended (Auto-weekly):**
- App preferences (iTerm/Raycast/Rectangle/Alfred configs)
- Hammerspoon/Karabiner configurations
- VS Code settings & extensions list
- macOS defaults (Dock, Finder preferences)
- Size: ~10-50 MB, Time: ~2-5 minutes

**Tier 3 - Optional (Manual on-demand):**
- Application Support directories (large, rarely needed)
- Caches and temporary data
- Historical backups (older than 10 backups get auto-cleanup)
- Size: ~100 MB - 2 GB, Time: ~5-15 minutes

### Backup Command Interface

```bash
# Quick backup - only what changed since last backup
./scripts/backup.sh

# Full backup - all tiers
./scripts/backup.sh --full

# Tier-specific backup
./scripts/backup.sh --tier essential
./scripts/backup.sh --tier apps
./scripts/backup.sh --tier optional

# Dry run - shows what would be backed up
./scripts/backup.sh --dry-run

# Force backup even if no changes
./scripts/backup.sh --force
```

### Change Detection

- Uses file modification times + content hashes (sha256)
- Only backs up changed files to new timestamped directory
- Creates hardlinks for unchanged files (space-efficient deduplication)
- State file tracks last backup time per tier

### Backup Retention Policy

- **Daily backups:** Keep last 10
- **Weekly backups:** Keep last 4
- **Monthly archives:** Keep first backup of each month
- **Automatic cleanup:** Runs after each backup, removes old backups
- **Disk space limit:** Warn if backups exceed 5 GB

## Restoration System

### Restore Command Interface

```bash
# Interactive mode - walk through tiers
./scripts/restore.sh

# Quick restore - essentials only
./scripts/restore.sh --essential

# Full restore - everything
./scripts/restore.sh --full

# Select from specific backup
./scripts/restore.sh --backup 2025.01.13_12.00.00

# Preview mode - see what would be restored
./scripts/restore.sh --preview

# List available backups
./scripts/restore.sh --list
```

### Interactive Restore Flow

1. **Scan backups** - Shows available timestamps with size/age
2. **Select backup** - Choose timestamp or use "latest"
3. **Tier selection** - Prompts for each category:
   ```
   ✓ Restore Essential configs? (shell, git, ssh/gpg) [Y/n]: y
   ? Restore App preferences? (iTerm, Raycast, Rectangle) [y/N]:
   ? Restore Hammerspoon/Karabiner? [y/N]:
   ? Restore macOS system preferences? [y/N]:
   ```
4. **Pre-restore validation** - Checks for conflicts, shows what will be overwritten
5. **Apply with backups** - Creates `.backup-{timestamp}` of existing files
6. **Post-restore steps** - Prompts to restart apps, reload shell, etc.

### Safety Features

- Automatic backup of existing files before restore
- Validation check: Verify restore completed successfully
- Rollback option: Revert failed restore using automatic backups
- Dry-run mode: Preview changes before applying

## Automation & Scheduling

### Catch-Up Scheduling

**Challenge:** launchd skips jobs if computer is off/sleeping at scheduled time.

**Solution:** Hybrid approach with state-based catch-up logic.

**Schedule:**

**Daily (Essential Tier):**
- Check times: 9 AM, 1 PM, 5 PM (every 4 hours during workday)
- Condition: Only run if last daily backup > 20 hours ago
- Result: If working, backs up. If off for weekend, catches up Monday at 9 AM

**Weekly (Full Backup):**
- Check time: Monday 12:30 PM
- Condition: Only run if last weekly backup > 6 days ago
- Result: Even if offline Monday, runs when next available

### State File System

**Location:** `~/.dotfiles-backup-state`

**Format:**
```ini
last_daily_backup=2025-01-13T09:00:00
last_weekly_backup=2025-01-06T12:30:00
last_manual_backup=2025-01-12T18:30:00
backup_count_daily=10
backup_count_weekly=4
```

**Logic:**
```bash
should_run_daily_backup() {
  last_backup=$(get_state last_daily_backup)
  hours_since_backup=$(( ($(date +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%S" "$last_backup" +%s)) / 3600 ))
  [ $hours_since_backup -gt 20 ]
}
```

### Launchd Configuration

**Daily Check Agent:** `~/Library/LaunchAgents/com.dotfiles.backup.daily.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.dotfiles.backup.daily</string>

  <key>ProgramArguments</key>
  <array>
    <string>~/dotfiles/scripts/backup.sh</string>
    <string>--tier</string>
    <string>essential</string>
    <string>--check-schedule</string>
    <string>--quiet</string>
  </array>

  <key>StartCalendarInterval</key>
  <array>
    <dict>
      <key>Hour</key><integer>9</integer>
      <key>Minute</key><integer>0</integer>
    </dict>
    <dict>
      <key>Hour</key><integer>13</integer>
      <key>Minute</key><integer>0</integer>
    </dict>
    <dict>
      <key>Hour</key><integer>17</integer>
      <key>Minute</key><integer>0</integer>
    </dict>
  </array>

  <key>WorkingDirectory</key>
  <string>~/dotfiles</string>

  <key>StandardOutPath</key>
  <string>~/dotfiles/logs/backup-daily.log</string>

  <key>StandardErrorPath</key>
  <string>~/dotfiles/logs/backup-daily.err</string>
</dict>
</plist>
```

**Weekly Check Agent:** `~/Library/LaunchAgents/com.dotfiles.backup.weekly.plist`

Similar structure with Monday 12:30 PM schedule.

### Scheduler Management

```bash
# Enable scheduled backups
./scripts/backup-scheduler.sh enable

# Disable scheduled backups
./scripts/backup-scheduler.sh disable

# Check scheduler status
./scripts/backup-scheduler.sh status

# Trigger backup immediately (useful for testing)
./scripts/backup-scheduler.sh run-now

# View logs
./scripts/backup-scheduler.sh logs
```

### Notifications

- macOS notification center on successful backup
- Summary notification: "Backup complete: 15 files changed, 23 MB, 45 seconds"
- Error notification if backup fails
- Warnings: Disk space low, backup validation failed

## Mackup Application Configuration

### App Categories

**Shell & Development (Essential):**
```ini
[application]
name = Git
configuration_files = .gitconfig, .gitignore_global

[application]
name = SSH
configuration_files = .ssh/config, .ssh/known_hosts
# .ssh/private_key excluded via .mackup.cfg ignore rules

[application]
name = Vim
configuration_files = .vimrc, .vim/
```

**Terminal & CLI Tools (Essential):**
```ini
[application]
name = iTerm2
configuration_files = Library/Preferences/com.googlecode.iterm2.plist
xcode = true

[application]
name = tmux
configuration_files = .tmux.conf

[application]
name = fzf
configuration_files = .fzf.bash, .fzf.zsh
```

**Window Management & Automation (Recommended):**
```ini
[application]
name = Hammerspoon
configuration_files = .hammerspoon/init.lua, .hammerspoon/Spoons

[application]
name = Karabiner-Elements
configuration_files = .config/karabiner/karabiner.json

[application]
name = Rectangle
configuration_files = Library/Preferences/com.knollsoft.Rectangle.plist

[application]
name = Raycast
configuration_files = Library/Application\ Support/Raycast
```

**Editor Configuration (Recommended):**
```ini
[application]
name = VSCode
configuration_files = Library/Application\ Support/Code/User/settings.json
xcode = true

[application]
name = Zed
configuration_files = Library/Application\ Support/Zed
```

**macOS System Preferences (Recommended):**
```ini
[application]
name = macOS Defaults
configuration_files = settings/manual/macos-defaults.sh
```

### Custom Mackup Config

**Main Config:** `settings/mackup/.mackup.cfg`

```ini
[storage]
engine = file_system
path = ~/dotfiles/settings/mackup/backups
directory = .

[applications_to_ignore]
# Add apps that should never be backed up here

[settings]
# Disable Dropbox warnings (we're using local storage)
warnings = false
```

## Implementation Phases

### Phase 1: Core Backup Infrastructure
1. ✅ Create design document
2. Create enhanced directory structure (settings/mackup hierarchy)
3. Update `.gitignore` to exclude backup timestamps
4. Build `backup.sh` with:
   - Tier selection (--tier essential|apps|full)
   - Change detection (file mod times + hashes)
   - State file management
   - Hardlink deduplication
5. Create Mackup app configs (.cfg files) for essential tools

### Phase 2: Restoration System
6. Build `restore.sh` with:
   - Interactive tier selection
   - Pre-restore validation
   - Automatic backup of existing files
   - Conflict detection
7. Add backup creation (safety net before overwriting)
8. Implement rollback capability

### Phase 3: Automation & Scheduling
9. Create `backup-scheduler.sh` for launchd management:
   - enable/disable/status commands
   - launchd plist generation
   - Service load/unload
10. Build state file system for catch-up scheduling
11. Create launchd plist files with multiple triggers
12. Add macOS notifications for backup status

### Phase 4: Integration & Polish
13. Create catalog.json generator (backup metadata)
14. Add optional pre-commit git hook
15. Implement backup cleanup logic (keep last 10 + monthly)
16. Add health checks:
    - Verify backup integrity
    - Disk space monitoring
    - Validation tests
17. Update documentation (setup.md, troubleshooting)

### Phase 5: Testing & Validation
18. Test backup on current machine
19. Test restore on clean VM or separate account
20. Validate all captured settings work correctly
21. Document restore process in setup.md
22. Create test checklist

## Success Criteria

### Functional Requirements
- ✅ Backup captures shell configs, app settings, system preferences
- ✅ Automated backups run on schedule (with catch-up for missed runs)
- ✅ Manual backup command works for all tiers
- ✅ Restore system can recover settings on fresh macOS install
- ✅ Git repo stays clean (no bloated backup files in history)
- ✅ Backup retention policy works (old backups cleaned up)

### Non-Functional Requirements
- Daily backup < 1 minute for essential tier
- Weekly backup < 5 minutes for full backup
- Total backup size < 5 GB (with retention policy)
- Restore completes < 10 minutes for full restoration
- Clear user feedback (logs, notifications, progress indicators)

### Usability Requirements
- Single command to backup: `backup.sh`
- Single command to restore: `restore.sh`
- Clear documentation in setup.md
- Troubleshooting guide for common issues
- Preview/dry-run mode for safety

## Security Considerations

1. **Secrets Management:**
   - SSH/GPG keys backed up encrypted (GPG symmetric encryption)
   - API keys excluded via Mackup ignore rules
   - .zsh_secrets already gitignored (existing practice)

2. **Permissions:**
   - Backup directories: 700 (owner only)
   - State file: 600 (owner read/write only)
   - Preserve original permissions on restore

3. **Validation:**
   - Verify no sensitive data in backups before commit
   - Scan for secrets with `git-secrets` or similar

## Maintenance

### Regular Tasks
- Review backup catalog monthly
- Test restore quarterly on clean system
- Update Mackup configs when adding new apps
- Review retention policy annually

### Backup Health Monitoring
```bash
# Check backup status
./scripts/backup.sh --status

# Verify backup integrity
./scripts/backup.sh --verify

# List all backups with sizes
./scripts/backup.sh --list
```

## Open Questions

1. **Cloud Backup Sync:** Should backups sync to iCloud/GitHub/other cloud?
   - Decision: Local only initially, add optional cloud sync later

2. **Encryption:** Encrypt backups before git push?
   - Decision: Local backups unencrypted (same security as macOS), encrypt if adding cloud sync

3. **Cross-Machine:** Support restoring to different machine?
   - Decision: Yes, design for it, but warn about machine-specific settings

## References

- [Mackup Documentation](https://github.com/lra/mackup)
- [launchd.plist man page](https://manpages.org/launchd.plist)
- [Existing dotfiles backup strategies](https://dotfiles.github.io/)
