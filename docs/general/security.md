---
title: Security & Environment Setup
created: 2025-12-04
last_updated: 2026-01-12
category: general
tags: [security, 1password, secrets, ssh]
---

# Security & Environment Setup

This repository uses **1Password** to manage all sensitive credentials and API keys. No secrets are stored in the repository itself.

## 1Password Integration

This dotfiles repository is designed to work seamlessly with 1Password's secret management:

### Environment Variables with 1Password

The `.env.schema` file defines all required environment variables that are loaded from 1Password using the `exec()` function. To use this:

1. **Install 1Password CLI**:

```bash
brew install 1password-cli
```

2. **Authenticate with 1Password**:

```bash
op account add
```

3. **Load environment variables**:

```bash
# Using @env-spec (recommended)
source <(op run --env-file shell/.env.schema)
```

### Environment Variables Managed in 1Password

The following environment variables are stored in 1Password and should NOT be committed to this repository:

- **API Keys**: ANTHROPIC_AUTH_TOKEN, Z_AI_API_KEY, CONTEXT7_API_KEY, GITHUB_TOKEN, GEMINI_API_KEY, DEEPSEEK_API_KEY, OPENAI_API_KEY, OPENROUTER_API_KEY, SMITHERY_API_KEY
- **Shell Secrets**: `.zsh_secrets` (loaded from home directory, not committed)

### SSH Keys with 1Password SSH Agent

SSH keys are managed through 1Password's SSH agent:

1. **Configure SSH agent** in `1password/ssh/agent.toml`:
   - Specifies which 1Password vaults contain SSH keys
   - Currently configured to use "Secrets" and "Private" vaults

2. **Enable 1Password SSH agent**:
   ```bash
   # Add to ~/.zshrc
   export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
   ```

3. **Test SSH agent**:
   ```bash
   SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l
   ```

## Git Configuration with 1Password

To use 1Password for git credentials:

1. **Install 1Password SSH agent** for git:
   ```bash
   # In ~/.zshrc
   export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
   ```

2. **Configure git to use SSH**:
   ```bash
   git config --global url."git@github.com:".insteadOf "https://github.com/"
   ```

## Installation

When you first set up these dotfiles:

```bash
./install.sh
```

This will:
- Create symlinks for shell configuration
- Set proper permissions (600) on `.zsh_secrets`
- Link the 1Password SSH agent config

## What's NOT Included (For Security)

The following files are in `.gitignore` and should be created locally:

- `.zsh_secrets` - Local shell secrets (created by you)
- `.env.local` - Any local-only environment variables
- `.claude.json` - VS Code extension configuration with user data
- Any `.env*` files with local overrides

## Making This Repository Public

This repository is safe to make public because:

1. ✅ All API keys are loaded from 1Password using `op read`
2. ✅ No `.env` files are committed
3. ✅ SSH keys are stored in 1Password, not in the repo
4. ✅ Local secrets files (`.zsh_secrets`) are in `.gitignore`
5. ✅ IDE configuration files with personal data are excluded

### Before Making Public

1. **Verify git history** - Ensure no secrets were committed in the past:
   ```bash
   git log --all -p -- shell/.env | grep -i "api\|token\|secret\|password"
   ```

2. **Check current status**:
   ```bash
   git status
   git diff --cached
   ```

3. **Use git-secrets** to prevent accidental commits:
   ```bash
   brew install git-secrets
   git secrets --install
   git secrets --register-aws
   ```

## Troubleshooting

### 1Password CLI Not Finding Items

If you get `Item not found` errors:
- Verify the vault names in `1password/ssh/agent.toml` match your 1Password vaults
- Verify the item names exist: `op item list --vault Secrets`
- Check you're signed in: `op account get --account`

### SSH Agent Not Working

If SSH keys aren't available:
```bash
# Verify SSH auth socket is set
echo $SSH_AUTH_SOCK

# Test the agent directly
SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l
```

### Environment Variables Not Loading

Make sure to use the correct command:
```bash
# Using @env-spec
source <(op run --env-file shell/.env.schema)

# Or directly in commands
op run -- npm start
```

## References

- [1Password SSH Agent Documentation](https://developer.1password.com/docs/ssh/agent/)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [@env-spec Documentation](https://varlock.dev/env-spec)
