w# Claude Secure Launcher

A secure sandbox wrapper for Claude Code with intelligent project detection.

## Quick Start

```bash
# Add to your shell profile
echo 'source /Users/jason/dotfiles/.claude/claude-secure/iterm2-integration.sh' >> ~/.zshrc
source ~/.zshrc

# Vanilla Claude (no wrapper, no sandbox)
claude --dangerously-skip-permissions

# Smart sandbox (auto-detect preset, safe)
claude-smart --dangerously-skip-permissions
c --dangerously-skip-permissions       # Quick alias
```

## Commands

- **`claude`** – Vanilla Claude binary with no modifications
- **`claude-smart`** – Intelligent sandbox with preset auto-detection (recommended)
- **`claude-sandbox <preset>`** – Explicit sandbox with specific preset
- **`claude-desktop`** – Smart sandbox using Claude Desktop credentials (no env injection)
- **`c`, `cl`** – Quick aliases for `claude-smart`
- **`cdesk`** – Quick alias for `claude-desktop`

## Features

- 🎯 **Smart Project Detection**: Automatically finds project-specific configurations
- 🔒 **Secure Sandboxing**: macOS sandbox restricts access to only necessary directories
- 📁 **Read-Only Dotfiles**: Protects your dotfiles from accidental modification
- 📝 **Audit Logging**: All sessions logged with full details
- 🚀 **One-Command Usage**: Works in any directory with automatic fallback
- 🖥️ **Desktop Auth Option**: Avoids z.ai env injection and authenticates via Claude Desktop session

## Files

- `claude-secure-wrapper.sh` - Main sandbox wrapper
- `claude-smart-simple` - Smart project detector
- `claude-smart` - Alternative TOML parser version
- `projects.toml` - Project configurations
- `iterm2-integration.sh` - Shell aliases and iTerm2 integration
- `term-integration.sh` - Alternative shell integration with Desktop auth option
- `README.md` - Quick overview
- `SETUP.md` - Complete setup guide
- `shims/` - Tool shims for secure execution

## Security

- **Home Directory Protection**: `no_home=true` blocks all home access by default
- **Read-Only Dotfiles**: Your dotfiles can be read but not modified
- **Project Isolation**: Only allows access to specific project directories
- **Sandbox Enforcement**: Every session runs in macOS sandbox

For complete setup instructions, see [SETUP.md](SETUP.md).

## Desktop Auth Mode

Use `claude-desktop` when you want to authenticate using Claude Desktop instead of injecting API keys from 1Password.

Requirements:

- Claude Desktop is installed and signed in.
- Session env files exist under `~/.claude/session-env` (created by Desktop).


Behavior:

- The wrapper sets `ANTHROPIC_BASE_URL=https://api.anthropic.com` and skips secret injection.
- If `ANTHROPIC_AUTH_TOKEN` is found in session env, it is preferred over `ANTHROPIC_API_KEY`.
- `headersHelper` remains in env-only mode to avoid additional biometric prompts.

## Diagnostics

Quickly check that Claude Desktop credentials are available and recognized:

- `claude-desktop-status` – prints session env files and masked presence of keys
- `cds` – short alias for the status command

## Optional Safeguards

If you prefer extra protection against accidental deletions while keeping normal edits:

- Deny deletes: add `(deny file-write-unlink (subpath "<PROJECT_ROOT_REAL>"))`
- Deny renames: add `(deny file-rename* (subpath "<PROJECT_ROOT_REAL>"))`

This preserves `file-write-data` and `file-write-create` (edits and new files) while blocking unlink/rename operations that can cause data loss. You can add these lines inside the sandbox profile generation in `claude-secure-wrapper.sh` after the project allow rules.
