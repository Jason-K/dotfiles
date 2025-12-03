# dotfiles

Personal macOS configuration and setup automation.

## Quick Start

On a new machine:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## Structure

```
dotfiles/
├── shell/              # Shell configuration files
│   ├── .zshrc         # Main zsh configuration
│   ├── .zshenv        # Environment variables
│   ├── .p10k.zsh      # Powerlevel10k theme config
│   └── .env.schema    # API key specs for Varlock (1Password integration)
├── bin/               # Custom scripts
├── git/               # Git configuration
├── hammerspoon/       # Hammerspoon automation
├── hazel/             # Hazel rules
├── karabiner/         # Karabiner Elements config
│   └── karabiner.ts/  # TypeScript config builder
├── km/                # Keyboard Maestro macros
├── macos/             # macOS system preferences
│   ├── dock.sh
│   └── macos-defaults.sh
├── vscode/            # VS Code settings
├── Brewfile           # Homebrew packages
├── bootstrap.sh       # Full setup for new machines
└── install.sh         # Symlink dotfiles to ~
```

## Files

### Shell Configuration

All shell configuration files live in `~/dotfiles/shell/` and are symlinked to `~`:

- **`.zshrc`**: Main interactive shell configuration
  - Oh My Zsh with Powerlevel10k theme
  - Fast syntax highlighting
  - fzf integration for fuzzy finding
  - zoxide for smart directory jumping
  - Custom aliases and functions

- **`.zshenv`**: Environment variables loaded for all shells

- **`.p10k.zsh`**: Powerlevel10k prompt configuration

- **`.zsh_secrets`**: API keys and secrets (see Security below)

### Key Features

**Performance Optimizations:**
- Completion cache with 24-hour refresh cycle
- Conditional tool initialization (only load if installed)
- Parallel PATH management to avoid duplicates
- Fast syntax highlighting instead of OMZ default

**Tool Wrappers:**
- `claude()` - Claude CLI with automatic `.env.schema` management
- `open_codex` / `open-codex` - OpenCodex with varlock secret injection
- `y()` - Yazi file manager with smart directory switching
- `fif()` - Fuzzy search file contents with preview
- `fkill()` - Interactive process killer with fzf

**Aliases:**
- Modern replacements: `eza` for ls, `bat` for cat, `micro` for nano
- Quick navigation: `..`, `...`, `docs`, `scripts`, etc.
- Maintenance: `update`, `fixmb`, `lscleanup`, `emptytrash`

## Installation

### New Machine Setup

Run the bootstrap script to set up everything:

```bash
./bootstrap.sh
```

This will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install packages from Brewfile
4. Install Oh My Zsh and plugins
5. Create symlinks to dotfiles
6. Optionally apply macOS defaults

### Update Existing Installation

If you've already run bootstrap and just want to update symlinks:

```bash
./install.sh
```

### Manual Symlink Creation

The `install.sh` script creates these symlinks:

```bash
~/.zshrc -> ~/dotfiles/shell/.zshrc
~/.zshenv -> ~/dotfiles/shell/.zshenv
~/.p10k.zsh -> ~/dotfiles/shell/.p10k.zsh
~/.zsh_secrets -> ~/dotfiles/shell/.zsh_secrets
```

## Security

### API Keys & Secrets

The `.zsh_secrets` file stores API keys and is:
- **Included in `.gitignore`** to prevent accidental commits
- Set to `600` permissions (owner read/write only)
- Located at `~/dotfiles/shell/.zsh_secrets` with symlink from `~`

**Template:**

```bash
# API Keys - DO NOT COMMIT TO GIT

# Gemini API
export GEMINI_API_KEY="your-key-here"

# DeepSeek API
export DEEPSEEK_API_KEY="your-key-here"

# OpenAI API
export OPENAI_API_KEY="your-key-here"

# OpenRouter API
export OPENROUTER_API_KEY="your-key-here"

# Context7 API
export CONTEXT7_KEY="your-key-here"

# Z.ai GLM API (for Claude Code)
export ANTHROPIC_AUTH_TOKEN="your-key-here"
export Z_AI_API_KEY="your-key-here"
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
```

**Alternative: 1Password / Varlock**

For enhanced security, consider using:
- [1Password CLI](https://developer.1password.com/docs/cli/) for secret management
- [Varlock](https://github.com/yourusername/varlock) for just-in-time secret injection

## Dependencies

### Required

- macOS (tested on macOS 11+)
- [Homebrew](https://brew.sh/)
- Git (via Xcode Command Line Tools)

### Installed by Bootstrap

See `Brewfile` for complete list. Key tools:
- **Zsh**: Default shell
- **Oh My Zsh**: Zsh configuration framework
- **Powerlevel10k**: Fast, customizable prompt
- **fzf**: Fuzzy finder
- **eza**: Modern ls replacement
- **bat**: Cat with syntax highlighting
- **zoxide**: Smarter cd command
- **ripgrep**: Fast grep alternative
- **yazi**: Terminal file manager

## Customization

### Adding New Dotfiles

1. Move file to appropriate directory in `~/dotfiles/`
2. Add symlink creation to `install.sh`
3. Update this README

### Modifying Shell Configuration

Edit files in `~/dotfiles/shell/`:
- Changes take effect immediately (files are symlinked)
- Run `source ~/.zshrc` to reload configuration
- Test startup time: `for i in {1..5}; do time zsh -i -c exit; done`

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

See [karabiner/README.md](karabiner/README.md) for detailed documentation.

### macOS Settings

Edit `macos/macos-defaults.sh` to customize system preferences.

**⚠️ Warning**: These modify system settings. Review before running.

## Maintenance

### Update Packages

```bash
update  # alias for topgrade
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
