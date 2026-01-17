---
title: Dotfiles Backup System
created: 2025-01-13
last_updated: 2026-01-16
category: components
tags: [backup, restore, chezmoi, git, automation]
---

# Dotfiles Backup System

Comprehensive, automated backup and restoration system for macOS dotfiles and application settings.

## Overview

The backup system has been modernized to use **Chezmoi** and **Git** as the core engines, replacing the legacy Mackup system.

It provides:
- **Git-based Versioning:** All settings are committed to the git repo.
- **Automated Sync:** `backup.sh` automatically pulls your local edits (`chezmoi re-add`) before committing.
- **System Inventory:** Captures installed apps, Homebrew packages, and versions.
- **Tiered Inventory:** While settings are always fully backed up, the *inventory* depth can be adjusted (Essential vs Full).

## Quick Start

### Daily Usage

```bash
# Standard backup (commits changes + enables essential inventory)
./scripts/backup.sh

# Full backup (includes detailed system diagnostics in inventory)
./scripts/backup.sh --full

# Restore on a new machine
./scripts/restore.sh
```

## How It Works

### 1. Settings Backup (Chezmoi)
Unlike the old system which blindly copied files, `backup.sh` leverages Chezmoi:
1. **Sync:** Runs `chezmoi re-add` to update the repo with any changes you made to tracked files (e.g., `~/.zshrc`).
2. **Commit:** Runs `git add .` and `git commit` to save a snapshot of your configuration.
3. **Safety:** If no changes are detected, it skips the commit to keeping history clean.

### 2. System Inventory (Snapshot)
Since Git only tracks *configuration files*, we also need to track *what is installed*.
`backup.sh` creates a timestamped folder in `backups/` containing:
- `Brewfile`: Complete list of Homebrew packages/casks.
- `apps/`: Lists of App Store and `/Applications` apps.
- `system/` (Full Tier only): Detailed macOS defaults, launch agents, and cron jobs.

## Tiers

| Tier | Settings (Chezmoi) | Inventory Depth | Speed |
|------|-------------------|-----------------|-------|
| **Essential** (Default) | **All Tracked Files** | Packages, Apps, Leaves | ~5s |
| **Full** | **All Tracked Files** | Above + Defaults, LaunchServices, Dev Versions | ~30s |

*Note: Since Chezmoi handles the heavy lifting of settings efficiently, "Essential" is sufficient for 99% of daily use.*

## Restoration

Restoration is handled by `scripts/restore.sh`.

### Process
1. **Checks Prerequisites:** Installs Homebrew and Chezmoi if missing.
2. **Applies Settings:** Runs `chezmoi apply` to restore dotfiles.
3. **Installs Apps:** Runs `brew bundle install` using `~/dotfiles/brew/Brewfile`.

```bash
# Restore everything
./scripts/restore.sh
```

## Automated Scheduling

The system includes a launchd agent for background backups.

```bash
# Enable automation
./scripts/backup-scheduler.sh enable

# Check status
./scripts/backup-scheduler.sh status
```

**Schedule:**
- Checks 3x daily (9am, 1pm, 5pm).
- only runs if the last backup is older than 20 hours.

## Troubleshooting

### "Chezmoi: unknown flag"
Ensure you are using the latest `backup.sh`. We use `chezmoi git -- <args>` to prevent flag parsing ambiguity.

### Restore Conflicts
If `chezmoi apply` reports a conflict (e.g., a file already exists), it will prompt you to resolve it.
- **Overwrite:** Use the version from the repo.
- **Keep:** Keep your local version (and run `backup.sh` later to commit it).

### Recovery Point
If you mess up your configuration, you can revert using Git:
```bash
# Reset to yesterday's state
git checkout HEAD@{1.day.ago} .
chezmoi apply
```
