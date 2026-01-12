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
| km/ | ❓ Unclear | Unknown purpose |
| hazel/ | ❓ Unclear | Unknown purpose |
| typinator/ | ❓ Unclear | Unknown purpose |
| settings/supercharge/ | ❓ Unclear | Unknown purpose |

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

## Unclear Directories (Need Clarification)

### km/
**Status:** ❓ Unclear
**Question:** Is this an intentional placeholder or forgotten?
**Action Needed:** Document purpose or remove

### hazel/
**Status:** ❓ Unclear
**Question:** Are Hazel rules stored in macOS ~/Library instead?
**Action Needed:** Document purpose or remove

### typinator/
**Status:** ❓ Unclear
**Question:** Still actively using Typinator text expansion?
**Action Needed:** Clarify active/archived status

### settings/supercharge/
**Status:** ❓ Unclear
**Question:** What is "supercharge"? Still used?
**Action Needed:** Document purpose or remove

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
