# Claude Secure Launcher

A secure sandbox wrapper for Claude Code with intelligent project detection.

## Quick Start

```bash
# Add to your shell profile
echo 'source /Users/jason/dotfiles/.claude/claude-secure/iterm2-integration.sh' >> ~/.zshrc
source ~/.zshrc

# Use anywhere
claude --dangerously-skip-permissions  # Smart detection + secure sandbox
c --dangerously-skip-permissions       # Quick alias
```

## Features

- 🎯 **Smart Project Detection**: Automatically finds project-specific configurations
- 🔒 **Secure Sandboxing**: macOS sandbox restricts access to only necessary directories
- 📁 **Read-Only Dotfiles**: Protects your dotfiles from accidental modification
- 📝 **Audit Logging**: All sessions logged with full details
- 🚀 **One-Command Usage**: Works in any directory with automatic fallback

## Files

- `claude-secure-wrapper.sh` - Main sandbox wrapper
- `claude-smart-simple` - Smart project detector
- `claude-smart` - Alternative TOML parser version
- `projects.toml` - Project configurations
- `iterm2-integration.sh` - Shell aliases and iTerm2 integration
- `README.md` - Quick overview
- `SETUP.md` - Complete setup guide
- `shims/` - Tool shims for secure execution

## Security

- **Home Directory Protection**: `no_home=true` blocks all home access by default
- **Read-Only Dotfiles**: Your dotfiles can be read but not modified
- **Project Isolation**: Only allows access to specific project directories
- **Sandbox Enforcement**: Every session runs in macOS sandbox

For complete setup instructions, see [SETUP.md](SETUP.md).