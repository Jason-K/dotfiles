---
title: Directory Structure Guide
created: 2026-01-12
last_updated: 2026-01-12
category: guides
tags: [structure, organization, directories]
---

# Directory Structure Guide

## Quick Reference

| Directory | Status | Purpose |
|-----------|--------|---------|
| shell/ | ✅ Active | Zsh configuration |
| bin/ | ✅ Active | Custom scripts |
| git/ | ✅ Active | Git config |
| vscode/ | ✅ Active | VS Code settings |
| karabiner/ | ✅ Active | Key remapping config |
| macos/ | ✅ Active | macOS defaults |
| 1password/ | ✅ Active | 1Password integration |
| hammerspoon/ | ✅ Active | Automation scripts |
| dnscrypt-proxy/ | 🟡 Mixed | Config + runtime logs |
| system-inventory/ | ⚠️ Archived | Dated snapshots (Dec 2025) |
| km/ | 📋 Placeholder | Keyboard Maestro settings (pending migration) |
| hazel/ | 📋 Placeholder | Hazel automation rules (pending migration) |
| typinator/ | 📋 Placeholder | Typinator text expansion rulesets (pending migration) |

---

## Active Directories (Frequently Edited)

### shell/
- Main zsh configuration
- Edited directly; changes take effect immediately
- Load time: ~1.2-1.4 seconds
- All files symlinked to ~

### bin/
- Custom executable scripts
- Kill and open app utilities
- Add new scripts as needed

### karabiner/
- Key remapping configuration
- Edit src/index.ts, run `npm run build`
- Output: ~/.config/karabiner/karabiner.json

### vscode/
- VS Code settings
- Multiple configurations available
- Secret injection via 1Password

---

## Reference Directories (Occasionally Edited)

### git/
- Global Git configuration
- Rarely changed

### 1password/
- 1Password SSH Agent config
- Rarely changed unless vault names change

### macos/
- System preference defaults
- Use with caution (modifies system settings)

### hammerspoon/
- Lua automation scripts
- Subproject with own git repo

---

## Placeholder Directories (Pending Migration)

### km/
**Status:** 📋 Placeholder
**Purpose:** Keyboard Maestro automation settings
**Migration Status:** Not yet migrated from ~/Library/Application Support/Keyboard Maestro/
**Action Needed:** Migrate Keyboard Maestro settings when ready

### hazel/
**Status:** 📋 Placeholder
**Purpose:** Hazel automation rules
**Migration Status:** Not yet migrated from ~/Library/Application Support/Hazel/
**Action Needed:** Migrate Hazel rules when ready

### typinator/
**Status:** 📋 Placeholder
**Purpose:** Typinator text expansion rulesets and settings
**Migration Status:** Not yet migrated from ~/Library/Application Support/Typinator/
**Action Needed:** Migrate Typinator configuration when ready

---

## Generated/Cached Directories (.gitignore'd)

These are properly ignored and safe to delete if needed:

- `.claude/` – Claude Code workspace cache
- `node_modules/` – Build dependencies
- `.mypy_cache/` – Python type checking
- `brew/backups/` – Old Brewfile backups

---

## Directories Needing Review

### system-inventory/
**Issue:** Contains dated snapshots (Dec 2025)
**Options:**
1. Archive to backups/system-inventory-2026-01-12/
2. Delete if not needed
3. Document retention policy

### dnscrypt-proxy/
**Issue:** Runtime logs stored with config
**Current state:** OK (logs in .gitignore)
**Future:** Consider separating runtime data
