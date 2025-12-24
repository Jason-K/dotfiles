# Claude Secure - Biometric Auth Fix

## Problem
Repeated 1Password biometric prompts during Claude Code sessions.

## Root Cause
MCP server `headersHelper` configs in `~/.claude.json` contained fallback patterns:
```json
"headersHelper": "KEY=\"${Z_AI_API_KEY:-$(op read 'op://...' 2>/dev/null)}\"; ..."
```

MCP HTTP servers spawn fresh shell processes for each `headersHelper` call, losing inherited environment variables and triggering `op read` for **every request**.

## Fix Applied

### 1. Patched `~/.claude.json` mcpServers
Removed `op read` fallbacks. Now uses env vars directly:
```json
"headersHelper": "printf '{\"Authorization\":\"Bearer %s\"...}' \"$Z_AI_API_KEY\""
```

Backup: `~/dotfiles/.claude/claude-secure/backups/.claude.json.bak_*`

### 2. Updated Scripts
- `claude-launcher.sh` - New clean launcher
- `claude-secure-nosandbox.sh` - Updated with skip-if-already-set logic
- `iterm2-integration-v2.sh` - Updated shell integration

## Usage

### Option A: Replace iterm2-integration.sh
```bash
# In ~/.zshrc, change:
source ~/dotfiles/.claude/claude-secure/iterm2-integration.sh
# To:
source ~/dotfiles/.claude/claude-secure/iterm2-integration-v2.sh
```

### Option B: Just use the updated nosandbox script
The existing `iterm2-integration.sh` sources `claude-secure-nosandbox.sh`, which is now fixed.

## How It Works Now

1. **First invocation**: `op run` resolves all secrets from `.claude-env` (single biometric)
2. **Secrets exported**: `ANTHROPIC_API_KEY`, `Z_AI_API_KEY`, `CONTEXT7_API_KEY`, etc.
3. **Child processes inherit**: MCP servers use `$Z_AI_API_KEY` directly from environment
4. **No fallback**: `headersHelper` never calls `op read`

## Files Modified
- `~/.claude.json` - MCP configs patched
- `~/dotfiles/.claude/claude-secure/claude-secure-nosandbox.sh` - Updated
- `~/dotfiles/.claude/claude-secure/iterm2-integration-v2.sh` - New version
- `~/dotfiles/.claude/claude-secure/claude-launcher.sh` - New standalone launcher
- `~/dotfiles/.claude/claude-secure/patch-mcp-configs.py` - Patching script

## Rollback
```bash
cp ~/dotfiles/.claude/claude-secure/backups/.claude.json.bak_* ~/.claude.json
```
