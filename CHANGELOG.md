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
