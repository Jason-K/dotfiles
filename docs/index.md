---
title: Documentation Index
created: 2026-01-12
last_updated: 2026-01-16
category: index
tags: [index, documentation, toc]
---

# Documentation Index

Complete listing of all dotfiles documentation with metadata.

## Quick Reference

| Category | Documents | Last Updated |
|----------|-----------|--------------|
| [General](#general) | 3 docs | 2026-01-16 |
| [Reviews](#reviews) | 5 docs | 2026-01-12 |
| [Guides](#guides) | 1 docs | 2026-01-16 |
| [Components](#components) | 3 docs | 2026-01-16 |

---

## General Documentation

### [Setup Guide](general/setup.md)
**Purpose:** Installation and configuration instructions (Chezmoi-based)
**Created:** 2025-12-06 | **Updated:** 2026-01-16
**Tags:** setup, installation, chezmoi

Quick start, installation guide, shell configuration, features, customization, and troubleshooting.

---

### [Security Guide](general/security.md)
**Purpose:** 1Password integration and secrets management
**Created:** 2025-12-04 | **Updated:** 2026-01-12
**Tags:** security, 1password, secrets, ssh

Environment variables, 1Password CLI integration, SSH agent configuration, git credentials, and security best practices.

---

### [Changelog](general/changelog.md)
**Purpose:** Version history and changes
**Created:** 2026-01-12 | **Updated:** 2026-01-12
**Tags:** changelog, versioning, history

Major releases, breaking changes, new features, and maintenance schedule.

---

## Reviews & Audits

### [Dotfiles Review](reviews/DOTFILES_REVIEW.md)
**Purpose:** Comprehensive repository review findings
**Created:** 2026-01-12 | **Updated:** 2026-01-12
**Tags:** review, audit, findings

Detailed analysis of structure, security, performance, and recommendations.

---

### [Implementation Guide](reviews/IMPLEMENTATION_GUIDE.md)
**Purpose:** Step-by-step improvement instructions
**Created:** 2026-01-12 | **Updated:** 2026-01-12
**Tags:** implementation, guide, step-by-step

75-minute quick wins with detailed instructions for documentation improvements.

---

### [Review Index](reviews/REVIEW_INDEX.md)
**Purpose:** Navigation guide for review documents
**Created:** 2026-01-12 | **Updated:** 2026-01-12
**Tags:** review, index, navigation

Reading order guide for review documents with time estimates.

---

### [Review Summary](reviews/REVIEW_SUMMARY.md)
**Purpose:** Quick 3-minute overview of findings
**Created:** 2026-01-12 | **Updated:** 2026-01-12
**Tags:** review, summary, overview

Executive summary of review findings and next steps.

---

### [Security Summary](reviews/SECURITY_SUMMARY.md)
**Purpose:** Security audit results
**Created:** 2026-01-12 | **Updated:** 2026-01-12
**Tags:** security, audit, findings

✅ PASSED - No critical issues. Comprehensive security checklist and testing procedures.

---

## Guides

### [Directory Structure Guide](guides/DIRECTORY_STRUCTURE.md)
**Purpose:** Explanation of every directory in dotfiles
**Created:** 2026-01-12 | **Updated:** 2026-01-16
**Tags:** structure, organization, directories

Quick reference table and active directories.

---

## Components

### [Dotfiles Backup System](components/backup-system.md)
**Purpose:** Comprehensive backup documentation
**Created:** 2025-01-13 | **Updated:** 2026-01-16
**Tags:** backup, restore, chevmoi, automation

Documentation for the `script/backup.sh` and `scripts/restore.sh` workflows.

---

### [Karabiner Configuration](components/karabiner.md)
**Purpose:** Key remapping with karabiner.ts
**Created:** 2025-11-15 | **Updated:** 2026-01-12
**Tags:** karabiner, keyboard, remapping

TypeScript configuration builder, editing workflow, and complex key mapping examples.

---

### [Shell Configuration](components/shell.md)
**Purpose:** Zsh shell setup and optimization
**Created:** 2026-01-12 | **Updated:** 2026-01-12
**Tags:** shell, zsh, refactoring, performance

Shell refactoring details, performance optimizations (25-30% faster), and modular architecture.

---

### [VS Code Setup](components/vscode.md)
**Purpose:** Visual Studio Code configuration
**Created:** 2025-12-05 | **Updated:** 2026-01-12
**Tags:** vscode, editor, setup

Multiple configurations, keybindings, settings synchronization, and snippets.

---

## Archived Documentation

### [Shell Improvements](archived/SHELL_IMPROVEMENTS.md)
**Purpose:** Historical shell refactoring documentation
**Archived:** 2026-01-12
**Tags:** shell, refactoring, history

Complete record of shell configuration refactoring with before/after metrics. See [Shell Configuration](components/shell.md) for current state.

---

## Document Maintenance

### Metadata Format
All documents use YAML frontmatter for tracking:
```yaml
---
title: Document Title
created: YYYY-MM-DD
last_updated: YYYY-MM-DD
category: general|reviews|guides|components|archived
tags: [tag1, tag2]
---
```

---

**Total Documents:** 12 active, 1 archived
**Last Updated:** 2026-01-16
