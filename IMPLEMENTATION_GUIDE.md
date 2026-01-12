# Implementation Guide: Dotfiles Refactoring

**Created:** January 12, 2026  
**Difficulty:** Easy (mostly documentation work)  
**Time:** 75 minutes for quick wins  
**Risk:** Very low (all reversible via git)

---

## Step 1: Create Backup Tag (5 minutes)

**Why:** Ensures you can rollback if needed

```bash
cd ~/dotfiles

# Create backup tag before any changes
git tag -a v1.0-pre-refactor \
  -m "Pre-refactoring checkpoint - documentation work

Completed:
- Shell configuration optimization (25-30% faster)
- 1Password integration
- Security audit

Next: Archive docs, add CHANGELOG, organize directories"

# Verify
git tag -l -n5
```

**Rollback if needed:**
```bash
git reset --hard v1.0-pre-refactor
```

---

## Step 2: Archive Completed Documentation (10 minutes)

**What:** Move SHELL_IMPROVEMENTS.md to docs/archived/  
**Why:** It documents completed work; keep history but out of main view

```bash
cd ~/dotfiles

# Create archive directory
mkdir -p docs/archived
git add docs/archived/.gitkeep 2>/dev/null || true

# Move the file
git mv SHELL_IMPROVEMENTS.md docs/archived/

# Commit
git add -A
git commit -m "docs(archive): move SHELL_IMPROVEMENTS to docs/archived

The shell configuration refactoring is complete. Historical
documentation moved to docs/archived/ for reference."

# Verify
ls -la docs/archived/
```

---

## Step 3: Add CHANGELOG.md (15 minutes)

**Why:** Track major versions and reversibility points

```bash
cat > ~/dotfiles/CHANGELOG.md << 'EOF'
# Changelog

All notable changes are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/)  
Versioning: [Semantic Versioning](https://semver.org/)

## [Unreleased]

### Added
- CHANGELOG.md for version tracking
- DIRECTORY_STRUCTURE.md for clarity

### Archived
- SHELL_IMPROVEMENTS.md moved to docs/archived/

## [1.0.0] - 2026-01-12

### Changed
- Shell configuration refactored for maintainability
  - 25-30% faster startup time
  - Modularized into separate files (aliases, functions, lazy-load)
  - Enhanced error handling
  - See docs/archived/SHELL_IMPROVEMENTS.md for details

### Added
- 1Password integration for secret management
- Karabiner.ts TypeScript configuration builder
- Hammerspoon automation scripts
- Bootstrap and install automation

### Fixed
- Security: Fixed command injection in update() function
- Performance: Removed duplicate PATH entries
- Shell: Clarified .zprofile vs .zshrc semantics

### Security
- All secrets in 1Password or .zsh_secrets (not in repo)
- SSH keys via 1Password SSH Agent
- Comprehensive .gitignore

---

## Maintenance Schedule

| Component | Frequency | Last Updated |
|-----------|-----------|--------------|
| Brewfile | Monthly | 2025-12-05 |
| Shell config | As-needed | 2026-01-12 |
| Karabiner | As-needed | 2025-11-15 |
| Hammerspoon | As-needed | TBD |
EOF

git add CHANGELOG.md
git commit -m "docs: add CHANGELOG.md for version tracking

- Documents major releases and changes
- Uses Keep a Changelog format
- Provides reversibility checkpoints"
```

---

## Step 4: Create DIRECTORY_STRUCTURE.md (20 minutes)

```bash
cat > ~/dotfiles/docs/DIRECTORY_STRUCTURE.md << 'EOF'
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

EOF

git add docs/DIRECTORY_STRUCTURE.md
git commit -m "docs: add comprehensive directory structure guide

- Explains purpose of each directory
- Marks active vs unclear vs archived
- Identifies action items"
```

---

## Step 5: Create Status Review Checklist (10 minutes)

```bash
cat > ~/dotfiles/docs/DIRECTORY_STATUS_REVIEW.md << 'EOF'
# Directory Status Review Checklist

Review status of unclear directories. Update as decisions are made.

## Directories Requiring Clarification

### [ ] km/
**Current:** Unknown  
**Question:** Active project or placeholder?  
**Decision:** _______________  
**Date:** _______________

### [ ] hazel/
**Current:** Unknown  
**Question:** Still using Hazel automation?  
**Decision:** _______________  
**Date:** _______________

### [ ] typinator/
**Current:** Unknown  
**Question:** Active text expansion tool?  
**Decision:** _______________  
**Date:** _______________

### [ ] settings/supercharge/
**Current:** Unknown  
**Question:** What is this directory for?  
**Decision:** _______________  
**Date:** _______________

---

## Decision Framework

### If Active
- [ ] Add to maintenance schedule
- [ ] Document setup/usage
- [ ] Ensure backups configured

### If Reference/Archived
- [ ] Mark as such in DIRECTORY_STRUCTURE.md
- [ ] Note reason and date
- [ ] Link to historical docs if applicable

### If Should Delete
- [ ] Ensure no dependencies
- [ ] Archive history if needed
- [ ] Remove via `git rm -r dirname/`

EOF

git add docs/DIRECTORY_STATUS_REVIEW.md
git commit -m "docs: add directory status review checklist

- Framework for decision-making
- Tracks uncertain directories
- Links to final decisions"
```

---

## Step 6: Clean macOS Metadata (5 minutes)

```bash
cd ~/dotfiles

# Remove .DS_Store files
find . -name ".DS_Store" -delete

# Verify .gitignore has it
echo ".DS_Store" | grep -F ".DS_Store" ~/.gitignore || \
  echo ".DS_Store" >> ~/.gitignore

# Commit
git add -A
git commit -m "chore: remove macOS metadata files

.DS_Store files removed. Already in .gitignore."
```

---

## Verification

After all steps, verify everything:

```bash
# Check commits
git log --oneline -10

# Check all files are tracked
git status  # Should show: nothing to commit

# Check tags
git tag -l -n5

# Check new files exist
ls -la docs/
cat CHANGELOG.md
cat docs/DIRECTORY_STRUCTURE.md
```

---

## Rollback Instructions

If anything goes wrong:

```bash
# Option 1: Reset to before refactoring
git reset --hard v1.0-pre-refactor

# Option 2: Restore specific file
git checkout v1.0-pre-refactor -- SHELL_IMPROVEMENTS.md

# Option 3: Undo last commit
git reset --soft HEAD~1
```

---

## Next Steps (Optional)

### This Month
1. Review unclear directories (km, hazel, typinator, supercharge)
2. Make decisions and update status checklist
3. Delete or document as appropriate

### Future
1. Consider making repo public (add LICENSE.md)
2. Organize runtime data separately
3. Add automated security checks (pre-commit hooks)

---

## Time Breakdown

- Step 1 (backup tag): 5 min ✓
- Step 2 (archive docs): 10 min ✓
- Step 3 (CHANGELOG): 15 min ✓
- Step 4 (directory guide): 20 min ✓
- Step 5 (status checklist): 10 min ✓
- Step 6 (cleanup): 5 min ✓

**Total: 75 minutes**

All changes are reversible and low-risk.
