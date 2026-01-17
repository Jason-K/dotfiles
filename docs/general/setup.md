---
title: Setup Guide
created: 2025-12-06
last_updated: 2026-01-12
category: general
tags: [setup, installation, bootstrap]
---

# dotfiles

Personal macOS configuration and setup automation.

## Quick Start

On a new machine:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/restore.sh
```

This will:
1. Install Homebrew and Chezmoi.
2. Apply your configuration settings via Chezmoi.
3. Install applications from the Brewfile.

## Structure

```
dotfiles/
├── chezmoi/                 # Source of Truth for all config files (Shell, Apps, etc.)
│   ├── dot_zshrc           # Main zsh config
│   ├── dot_hammerspoon/    # Hammerspoon config
│   └── private_Library/    # App Support configs (Hazel, Typinator, etc.)
├── shell/                   # Modular shell library (aliases, functions, sourced by .zshrc)
├── scripts/                 # Maintenance scripts
│   ├── backup.sh           # Backs up settings and captures inventory
│   └── restore.sh          # Restores settings and installs apps
├── backups/                 # Timestamped system inventories
├── karabiner/               # Karabiner Elements config builder
├── macos/                   # macOS system defaults script
└── docs/                    # Documentation
```

## Files & Configuration

### Chezmoi (The Core)
We use [Chezmoi](https://www.chezmoi.io/) to manage configuration files.
- **Source:** `~/dotfiles/chezmoi/`
- **Destination:** Your Home Directory (`~`)
- **Key Files:**
  - `dot_zshrc` → `~/.zshrc`
  - `dot_zshenv` → `~/.zshenv`
  - `dot_hammerspoon/` → `~/.hammerspoon/`

### Shell Library
While `~/.zshrc` is managed by Chezmoi, it sources modular files from `~/dotfiles/shell/`:
- `aliases.zsh`: Command shortcuts
- `functions.zsh`: Custom utility functions
- `exports.zsh`: Environmental variables

This allows for a clean separation: Chezmoi handles the *entry point* (`.zshrc`), but the *logic* remains in the Git repo at `~/dotfiles/shell`.

## Maintenance

### Making Changes
1. **Edit** the file on your local machine (e.g., `nano ~/.zshrc`).
2. **Run** `scripts/backup.sh` to capture the change.
   - This runs `chezmoi re-add`, capturing your edit into the repo.
   - It captures a system inventory.
   - It commits the changes to Git.

### Installing New Apps
1. `brew install <package>`
2. `scripts/backup.sh` (this will update the inventory in `backups/`)

### Performance
- **Fast Startup:** We use `fast-syntax-highlighting` and optimized usage of `nvm`/`pyenv` to keep shell startup under 0.5s.
- **Benchmarks:** Run `time zsh -i -c exit` to test.

## Security
Secrets (API keys) are excluded from this repo.
- **Method:** We use `~/.zsh_secrets` (sourced by `.zshrc`).
- **Management:** This file is in `.gitignore`. You must manually create it or populate it from 1Password on a new machine.

See [Security Guide](security.md) for details.

### Karabiner Configuration

The Karabiner-Elements configuration is built from TypeScript using [karabiner.ts](https://github.com/evan-liu/karabiner.ts).

**Edit configuration:**
```bash
code ~/dotfiles/karabiner/karabiner.ts/src/index.ts
```

**Rebuild and deploy:**
```bash
kbuild  # alias for: (cd ~/dotfiles/karabiner/karabiner.ts && npm run build)
```

This generates `~/.config/karabiner/karabiner.json` from the TypeScript source.

See [docs/components/karabiner.md](../components/karabiner.md) for detailed documentation.

### Claude Subagent System

The dotfiles include an integrated system for managing Claude Code subagents - specialized AI agents for different development tasks.

**Quick start:**
```bash
cd ~/my-project
claude setup              # Interactive agent selection wizard
```

**Available commands:**
```bash
claude list-agents       # Show 10 categories with 125+ agents
claude help              # Show enhanced help
claude setup             # Initialize project and select agents
```

**Agent categories:**
- 01-core-development (10 agents) - Backend, frontend, API, fullstack, mobile
- 02-language-specialists (24 agents) - Python, Go, Rust, TypeScript, Hammerspoon, etc.
- 03-infrastructure (12 agents) - DevOps, cloud, Docker, Kubernetes
- 04-quality-security (12 agents) - Testing, QA, security auditing
- 05-data-ai (12 agents) - Data science, ML, AI engineering
- 06-developer-experience (10 agents) - CLI tools, docs, libraries
- 07-specialized-domains (11 agents) - Finance, healthcare, gaming
- 08-business-product (11 agents) - Product management, UX research
- 09-meta-orchestration (8 agents) - Agent coordination, workflow
- 10-research-analysis (6 agents) - Research, investigation, synthesis

**How it works:**
1. Run `claude setup` in a project directory
2. Browse agent categories interactively
3. Select agents by number (e.g., `1,2,3` or `a` for all)
4. Agents are copied to `.claude/agents/` in your project
5. Claude can reference these agents for specialized guidance

### macOS Settings

Edit `macos/macos-defaults.sh` to customize system preferences.

**⚠️ Warning**: These modify system settings. Review before running.

## Backup System

Your dotfiles include an **automated backup and restoration system** for all settings and configurations.

### Quick Start

```bash
# Install Mackup (backup engine)
brew install mackup

# Run initial backup
cd ~/dotfiles
./scripts/backup.sh --full

# Enable automated backups (catch-up scheduling)
./scripts/backup-scheduler.sh enable

# Check status
./scripts/backup-scheduler.sh status
```

### Key Features

- **Automated backups** with smart catch-up scheduling
- **Tiered restoration** (essential → apps → full)
- **Change detection** - only backs up what changed
- **Safety features** - automatic backups before restore
- **Clean git history** - backups are gitignored

### Daily Usage

```bash
# Manual backup
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh

# View available backups
./scripts/restore.sh --list
```

**For complete documentation, see:** [Backup System Guide](../components/backup-system.md)

## Maintenance

### Update Packages

```bash
update  # alias for topgrade
```

### Backup Your Settings

```bash
# Manual backup (quick)
./scripts/backup.sh

# Full backup
./scripts/backup.sh --full

# View backup status
./scripts/backup-scheduler.sh status
```

### Reload Shell Configuration

```bash
reload  # alias for: source ~/.zshrc
```

### Measure Shell Startup Time

```bash
for i in {1..5}; do /usr/bin/time -l zsh -i -c exit; done
```

Target: < 0.5 seconds for interactive shell startup

## Troubleshooting

### Symlinks Not Working

Verify symlinks:

```bash
ls -la ~ | grep -E "\.zsh"
```

Recreate symlinks:

```bash
cd ~/dotfiles
./install.sh
```

### Slow Shell Startup

Profile startup:

```bash
zsh -xv 2>&1 | ts -i '%.s' | tee /tmp/zsh-startup.log
```

Check for:
- Multiple `compinit` calls
- Unguarded command evaluations
- Missing conditional checks for tools

### Oh My Zsh Plugin Issues

Reinstall plugins:

```bash
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/*
./bootstrap.sh
```

## Backup

Before major changes:

```bash
# Backup current configuration
cp ~/.zshrc ~/.zshrc.backup-$(date +%Y%m%d)
cp ~/.zshenv ~/.zshenv.backup-$(date +%Y%m%d)

# Backup entire dotfiles directory
cp -r ~/dotfiles ~/dotfiles.backup-$(date +%Y%m%d)
```

## License

MIT

## Contributing

This is a personal dotfiles repository. Feel free to fork and adapt to your needs.
