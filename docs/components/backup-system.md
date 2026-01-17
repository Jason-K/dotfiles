---
title: Dotfiles Backup System
created: 2025-01-13
last_updated: 2025-01-13
category: components
tags: [backup, restore, mackup, automation]
---

# Dotfiles Backup System

Comprehensive, automated backup and restoration system for macOS dotfiles and application settings.

## Overview

The backup system provides:
- **Automated backups** with smart catch-up scheduling (works even if computer is off)
- **System inventory capture** for clean reinstalls (installed packages, app lists, versions)
- **Tiered restoration** (essential → apps → full) for flexible recovery
- **Change detection** to only backup what's changed
- **Safety features** with automatic backup before restore
- **Space-efficient** deduplication using hardlinks
- **Clean git history** - backups are gitignored

## Quick Start

### First-Time Setup

```bash
# 1. Install Mackup (backup engine)
brew install mackup

# 2. Run initial backup
cd ~/dotfiles
./scripts/backup.sh --full

# 3. Enable automated backups
./scripts/backup-scheduler.sh enable

# 4. Check scheduler status
./scripts/backup-scheduler.sh status
```

### Daily Usage

```bash
# Manual backup (quick - essential tier only)
./scripts/backup.sh

# Manual backup (full - everything)
./scripts/backup.sh --full

# Restore from backup (interactive)
./scripts/restore.sh
```

## Backup System

### Tiers

The backup system uses three tiers to balance speed and comprehensiveness:

**Tier 1: Essential** (~30 seconds, ~1-5 MB)
- Shell configs (.zshrc, .zshenv, .gitconfig)
- SSH/GPG keys (public keys only)
- Core dev tools (vim, tmux, fzf)
- **System inventory:** Homebrew packages, App Store apps, installed applications

**Tier 2: Apps** (~2-5 minutes, ~10-50 MB)
- Everything in Essential, plus:
- Application preferences (iTerm, Raycast, Rectangle, Alfred)
- Hammerspoon and Karabiner configurations
- VS Code settings and extensions
- macOS defaults

**Tier 3: Full** (~5-15 minutes, ~100 MB - 2 GB)
- Everything in Apps, plus:
- Application Support directories
- Caches and temporary data
- Optional files
- **Complete system inventory:** dev toolchain versions, launch services, system defaults, login items

### Backup Commands

```bash
# Quick backup - essential tier (default)
./scripts/backup.sh

# Full backup - all tiers
./scripts/backup.sh --full

# Specific tier
./scripts/backup.sh --tier essential
./scripts/backup.sh --tier apps

# Preview what would be backed up
./scripts/backup.sh --dry-run

# Force backup even if no changes detected
./scripts/backup.sh --force
```

### Automated Scheduling

The backup scheduler uses launchd with **catch-up scheduling**:

```bash
# Enable automated backups
./scripts/backup-scheduler.sh enable

# Disable automated backups
./scripts/backup-scheduler.sh disable

# Check status
./scripts/backup-scheduler.sh status

# View logs
./scripts/backup-scheduler.sh logs

# Trigger immediate backup
./scripts/backup-scheduler.sh run-now
```

**Schedule:**
- **Daily checks:** 9 AM, 1 PM, 5 PM (runs if last backup >20 hours ago)
- **Weekly check:** Monday 12:30 PM (runs if last backup >6 days ago)

**Why catch-up?** If your computer is off or asleep during scheduled times, backups will automatically run at the next check time. No missed backups!

## Restoration System

### Interactive Restore

```bash
# Interactive mode - walk through options
./scripts/restore.sh
```

**Flow:**
1. Select from available backups (shows timestamp and size)
2. Choose tier to restore (essential, apps, or full)
3. Preview what will be restored
4. Confirm to proceed

### Non-Interactive Restore

```bash
# Quick restore from latest backup
./scripts/restore.sh --essential

# Restore specific tier
./scripts/restore.sh --apps
./scripts/restore.sh --full

# Restore from specific backup
./scripts/restore.sh --backup 2025.01.13_12.00.00

# Restore by number (from --list)
./scripts/restore.sh --backup 3

# Preview what would be restored
./scripts/restore.sh --preview
```

### List Available Backups

```bash
./scripts/restore.sh --list
```

Output:
```
Available Backups:

   1. 2025-01-13 at 12:00:00  (15 MB)
   2. 2025-01-12 at 09:00:00  (14 MB)
   3. 2025-01-11 at 17:00:00  (14 MB)
```

## How It Works

### Architecture

```
dotfiles/
├── scripts/
│   ├── backup.sh              # Smart backup command
│   ├── restore.sh             # Tiered restore
│   └── backup-scheduler.sh    # launchd management
├── settings/
│   └── mackup/
│       ├── backups/           # Git-ignored: timestamped backups
│       │   ├── latest/        # Symlink to most recent
│       │   ├── 2025.01.13_12.00.00/
│       │   └── 2025.01.12_09.00.00/
│       └── apps/              # Mackup app configs
│           ├── git.cfg
│           ├── vim.cfg
│           └── ...
└── logs/                      # Backup logs
```

### Backup Process

1. **Check state** - Read `~/.dotfiles-backup-state` for last backup time
2. **Detect changes** - Compare file modification times
3. **Create timestamped directory** - e.g., `2025.01.13_12.00.00/`
4. **Run Mackup** - Copy files to backup directory
5. **Capture system inventory** - Record installed packages, app lists, versions
6. **Update state** - Record backup time and increment counters
7. **Update 'latest' symlink** - Point to most recent backup
8. **Cleanup** - Remove old backups (keeps last 10)

### Restoration Process

1. **List backups** - Show available timestamps with sizes
2. **Select backup** - Choose by number, timestamp, or "latest"
3. **Select tier** - Choose essential, apps, or full
4. **Create safety backup** - Backup existing files before overwriting
5. **Run Mackup restore** - Copy files from backup to home directory
6. **Verify** - Confirm restore completed successfully

### Safety Features

**Before Restore:**
- Automatic backup of existing dotfiles to `safety-backup-{timestamp}/`
- Preview mode shows exactly what will change
- Prompts for confirmation before making changes

**After Restore:**
- Verification checks ensure files were restored correctly
- Rollback option using safety backups if something went wrong
- Post-restore reminders (restart apps, reload shell)

## Configuration

### State File

Location: `~/.dotfiles-backup-state`

Tracks:
- Last backup time per tier
- Backup counts per tier
- Used for catch-up scheduling logic

Format:
```ini
last_essential_backup=2025.01.13_12.00.00
last_apps_backup=2025.01.12_09.00.00
last_full_backup=never
backup_count_essential=5
backup_count_apps=2
backup_count_full=0
```

### Mackup App Configs

Located in: `settings/mackup/apps/*.cfg`

Each `.cfg` file defines what to backup for an application:

```ini
[application]
name = Git
configuration_files = .gitconfig, .gitignore_global
```

**To add a new app:**
1. Create `settings/mackup/apps/myapp.cfg`
2. Define files to backup
3. Run `./scripts/backup.sh --tier apps`

### Backup Retention

Default policy:
- Keep last 10 daily backups
- Keep last 4 weekly backups
- Keep first backup of each month (archive)
- Automatic cleanup after each backup

**To adjust retention policy**, edit the `cleanup_old_backups()` function in `scripts/backup.sh`.

## Troubleshooting

### Backup Issues

**Problem:** Mackup not found
```bash
# Solution: Install Mackup
brew install mackup
```

**Problem:** "Permission denied" running scripts
```bash
# Solution: Make scripts executable
chmod +x scripts/backup.sh scripts/restore.sh scripts/backup-scheduler.sh
```

**Problem:** Backup running but files not captured
```bash
# Solution: Check Mackup app configs exist
ls -la settings/mackup/apps/

# Solution: Run with debug output
./scripts/backup.sh --debug
```

### Restore Issues

**Problem:** Restore overwrites important files
```bash
# Solution: Check safety backup
ls -la settings/mackup/backups/safety-backup-*/

# Solution: Use preview mode first
./scripts/restore.sh --preview
```

**Problem:** Settings not applied after restore
```bash
# Solution: Restart affected applications
# Solution: Reload shell
source ~/.zshrc
```

### Scheduler Issues

**Problem:** Scheduled backups not running
```bash
# Check scheduler status
./scripts/backup-scheduler.sh status

# View logs
./scripts/backup-scheduler.sh logs

# Manually trigger backup
./scripts/backup-scheduler.sh run-now
```

**Problem:** "Operation not permitted" from launchd
```bash
# Solution: Grant Full Disk Access to terminal
# System Settings → Privacy & Security → Full Disk Access
# Add: Terminal or iTerm
```

### Disk Space

**Problem:** Backups taking too much space
```bash
# Check backup sizes
du -sh settings/mackup/backups/*/

# Force cleanup (keeps last 10)
./scripts/backup.sh --cleanup

# Manually remove old backups
rm -rf settings/mackup/backups/2025.01.*
```

## Advanced Usage

### Custom Backup Scripts

Create custom backup logic by extending the backup system:

```bash
#!/bin/bash
# Custom backup workflow

# Backup dotfiles
~/dotfiles/scripts/backup.sh --tier apps

# Backup additional directories
rsync -av ~/Projects ~/backup/

# Backup database dumps
pg_dump mydb > ~/backup/db-$(date +%Y%m%d).sql
```

### Git Integration

**Optional:** Add git hook to backup before committing:

```bash
# ~/.git-template/hooks/pre-commit
#!/bin/bash
~/dotfiles/scripts/backup.sh --tier essential --quiet
```

Install:
```bash
# Copy to git template
cp pre-commit ~/.git-template/hooks/

# Reinit existing repos
git init
```

### Cross-Machine Sync

Backups are local by default. To sync across machines:

**Option 1: Git LFS**
```bash
# Track large backups in git
git lfs track "settings/mackup/backups/*"
```

**Option 2: Rsync to remote**
```bash
# Add to backup.sh or scheduler
rsync -av ~/dotfiles/settings/mackup/backups/ user@server:backups/
```

**Option 3: Cloud storage**
```bash
# Sync backups to iCloud/Drive
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/dotfiles-backups \
    ~/dotfiles/settings/mackup/backups
```

## System Inventory

Every backup includes a **system inventory** in the `inventory/` subdirectory. This is critical for clean macOS reinstalls because Mackup only backs up configuration files, not what's installed on your system.

### What's Captured

**Essential & Apps Tiers:**
- `Brewfile` - Complete Homebrew package list for easy reinstallation
- `apps/brew_formulae.txt` - All installed Homebrew formulae
- `apps/brew_casks.txt` - All installed Homebrew casks
- `apps/brew_leaves.txt` - Top-level packages (not dependencies)
- `apps/mas_apps.txt` - App Store apps for `mas install`
- `apps/Applications_root.txt` - Drag-installed apps in /Applications
- `apps/Applications_user.txt` - User-specific apps

**Full Tier (additionally):**
- `system/login_items.txt` - Login items for restoration
- `system/launchctl_list.txt` - Running launch services
- `system/LaunchAgents_*.txt` - LaunchAgents listings
- `system/crontab.txt` - Cron jobs
- `dev/python_versions.txt` - Python versions via pyenv/asdf
- `dev/pip3_freeze.txt` - Python packages for `pip install -r`
- `dev/node_versions.txt` - Node.js versions via nvm/fnm/volta
- `dev/npm_global.txt` - Global npm packages
- `dev/vscode_extensions.txt` - VS Code extensions
- `configs/defaults_*.txt` - macOS system defaults

### Using Inventory for Clean Reinstall

After a clean macOS install:

```bash
# 1. Restore dotfiles with Mackup
cd ~/dotfiles
./scripts/restore.sh --full

# 2. Reinstall Homebrew packages
cd backups/2026.01.15_12.20.00/inventory
brew bundle --file=Brewfile

# 3. Reinstall App Store apps
xargs mas install < mas_apps.txt

# 4. Reinstall Python packages
pip3 install -r dev/pip3_freeze.txt

# 5. Reinstall VS Code extensions
cat dev/vscode_extensions.txt | xargs -L 1 code --install-extension
```

This gives you a complete working setup in minutes!

## Backup Catalog

### What's Backed Up

**Essential Tier:**
- ✅ Shell configs (.zshrc, .zshenv, .bashrc, etc.)
- ✅ Git configuration (.gitconfig, .gitignore)
- ✅ SSH keys (public only) and known_hosts
- ✅ GPG keys
- ✅ Vim/Neovim configuration
- ✅ Tmux configuration
- ✅ FZF configuration

**Apps Tier:**
- ✅ iTerm2 preferences
- ✅ Hammerspoon configuration
- ✅ Karabiner-Elements configuration
- ✅ Raycast settings
- ✅ Rectangle preferences
- ✅ VS Code settings
- ✅ macOS defaults (Dock, Finder, etc.)

**Full Tier:**
- ✅ Application Support directories
- ✅ Caches (optional, can be excluded)
- ✅ Historical backups (with retention policy)

### What's NOT Backed Up

- ❌ Private SSH/GPG keys (security)
- ❌ API keys and secrets (use 1Password instead)
- ❌ Large application caches (configurable)
- ❌ Temporary files

## Best Practices

1. **Test restores regularly**
   ```bash
   ./scripts/restore.sh --preview
   ```

2. **Monitor disk space**
   ```bash
   du -sh settings/mackup/backups
   ```

3. **Check logs periodically**
   ```bash
   ./scripts/backup-scheduler.sh logs
   ```

4. **Keep backups clean**
   - Automatic cleanup keeps last 10
   - Manually archive important backups before cleanup
   - Promote golden backups to version control

5. **Version control your configs**
   - Mackup configs in `settings/mackup/apps/*.cfg`
   - Backup scripts in `scripts/`
   - Both are git-tracked

## Maintenance

### Monthly Tasks

- Review backup catalog for new applications
- Test restore on clean system or VM
- Check disk space usage
- Archive important backups if needed

### Quarterly Tasks

- Full restore test on separate macOS account
- Update Mackup configs for new applications
- Review and optimize retention policy
- Update documentation

## References

- [Mackup Documentation](https://github.com/lra/mackup)
- [launchd.plist man page](https://manpages.org/launchd.plist)
- [Design Document](../plans/2025-01-13-dotfiles-backup-system.md)

## Support

Issues or questions?
1. Check logs: `./scripts/backup-scheduler.sh logs`
2. Run with debug: `./scripts/backup.sh --debug`
3. Review troubleshooting section above
4. Check design document for implementation details
