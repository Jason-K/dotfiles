---
title: Directory Structure Guide
created: 2026-01-12
last_updated: 2026-01-16
category: guides
tags: [structure, organization, directories, chezmoi]
---

# Directory Structure Guide

## Quick Reference

| Directory | Purpose |
|-----------|---------|
| **chezmoi/** | **Source of Truth** - Contains all managed config files (Shell, Apps, etc.) |
| **shell/** | **Shell Library** - Modular zsh files (`aliases.zsh`, `functions.zsh`) sourced by `.zshrc` |
| **scripts/** | **Automation** - `backup.sh`, `restore.sh`, `backup-scheduler.sh` |
| **backups/** | **Inventory** - Timestamped snapshots of installed packages/apps |
| **bin/** | **Binaries** - Custom executable scripts added to PATH |
| **macos/** | **Defaults** - macOS system preference scripts |
| **karabiner/**| **Input** - Karabiner-Elements TypeScript configuration |
| **docs/** | **Documentation** - This folder |

---

## Key Directories

### chezmoi/
This is where the actual configuration files live. They are "applied" to your home directory.
- `dot_zshrc` → `~/.zshrc`
- `dot_config/` → `~/.config/`
- `dot_hammerspoon/` → `~/.hammerspoon/`
- `private_Library/` → App Support files (Hazel, Typinator, KM)

### shell/
While `.zshrc` is managed by Chezmoi, we keep the *logic* in this directory to keep it modular and easily editable.
- `aliases.zsh`: Sourced by `.zshrc`
- `functions.zsh`: Sourced by `.zshrc`
- `exports.zsh`: Sourced by `.zshrc`

### scripts/
The engine room.
- `backup.sh`: Captures changes from `~` into `chezmoi/` + git, and creates system inventories.
- `restore.sh`: Applies `chezmoi/` to `~` and installs apps from `Brewfile`.

### backups/
Stores "Inventory Snapshots".
- Each backup creates a folder `YYYY.MM.DD_HH.MM.SS/`
- Contains `Brewfile`, `apps/` lists, etc.
- This ensures we know exactly what was installed at any point in time.

---

## Deleted / Migrated Directories (Historical)

The following directories have been **removed** or **migrated into Chezmoi**:
- `hammerspoon/` → moved to `chezmoi/dot_hammerspoon/`
- `km/` → moved to `chezmoi/private_Library/.../Keyboard Maestro/`
- `hazel/` → moved to `chezmoi/private_Library/.../Hazel/`
- `typinator/` → moved to `chezmoi/private_Library/.../Typinator/`
- `settings/` → Obsolete (Mackup legacy)
- `system-inventory/` → Obsolete (replaced by `backups/`)
