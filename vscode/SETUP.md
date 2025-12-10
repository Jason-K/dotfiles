# VSCode Claude Extension with z.ai API Setup

This guide explains how to configure the Claude VSCode extension to use the z.ai API with secrets managed through 1Password.

## Overview

Your terminal already has a working setup via the `claude()` function in `.zshrc`. This guide extends that to VSCode, which doesn't inherit shell environment variables when launched via the GUI.

## Solution Architecture

VSCode launched from the GUI doesn't inherit shell environment variables. We solve this with a wrapper function that:

1. Reads secrets from 1Password CLI before launching VSCode
2. Exports environment variables that VSCode inherits
3. Claude extension picks up these variables automatically

## Installation & Usage

### Quick Start

After updating your `.zshrc`, use:

```bash
code-secrets /path/to/project
code-secrets .                    # current directory
code-secrets help                 # show help
```

### What Gets Loaded

The `code-secrets` function loads these variables:

- `ANTHROPIC_AUTH_TOKEN` → GLM_API key from 1Password (required)
- `Z_AI_API_KEY` → GLM_API key from 1Password
- `ANTHROPIC_BASE_URL` → https://api.z.ai/api/anthropic
- `Z_AI_MODE` → ZAI
- `API_TIMEOUT_MS` → 3000000
- `CONTEXT7_API_KEY` → Context7 API (optional)
- `GITHUB_TOKEN` → GitHub token (optional)

## VSCode Extension Configuration

The Claude extension should detect these environment variables. To explicitly configure it in VSCode settings:

### Settings Location
- **Local project**: `.vscode/settings.json`
- **User settings**: `~/.config/Code - Insiders/User/settings.json`

### Example Configuration

```json
{
  "claude.apiKey": "${env:ANTHROPIC_AUTH_TOKEN}",
  "claude.apiBaseUrl": "https://api.z.ai/api/anthropic",
  "claude.requestTimeout": 30000
}
```

## Troubleshooting

### "1Password CLI not found"
Install with:
```bash
brew install 1password-cli
```

### "Failed to load secrets"
1. Verify 1Password is unlocked: `op account list`
2. Verify vault paths exist: `op item list --vault Secrets`
3. Check vault/item names match exactly:
   ```bash
   op read "op://Secrets/GLM_API/apikey2"
   op read "op://Secrets/Context7_API/api_key"
   ```

### Claude extension still using Anthropic
1. Verify variables are set: `env | grep Z_AI`
2. In VSCode, check Settings > Extensions > Claude > API Configuration
3. Restart VSCode after changing `.zshrc`

## Advanced: Manual Environment Setup

If you prefer setting variables manually for persistent use:

```bash
# Get secrets manually
export ANTHROPIC_AUTH_TOKEN=$(op read "op://Secrets/GLM_API/apikey2")
export Z_AI_API_KEY=$(op read "op://Secrets/GLM_API/apikey2")
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"

# Launch VSCode
open -a "Visual Studio Code" .
```

## Architecture Notes

### Why This Works

1. **Shell functions**: The `code-secrets` function runs in your shell
2. **1Password CLI**: `op` command accesses your vault
3. **Process inheritance**: Child processes (VSCode) inherit parent's environment variables
4. **Extension detection**: Claude extension reads `ANTHROPIC_AUTH_TOKEN` automatically

### Why GUI Launch Doesn't Work

- Clicking VSCode icon launches as a new process, not a child of your shell
- New processes don't inherit shell environment variables
- This requires explicit injection (our solution)

## Comparison: Terminal vs. VSCode

| Method | Setup | API Endpoint | Secrets |
|--------|-------|--------------|---------|
| Terminal `claude` function | Bash function in `.zshrc` | z.ai | 1Password ✓ |
| `code-secrets` | Alias to shell function | z.ai | 1Password ✓ |
| Normal `code` | Alias to `code-insiders` | Anthropic | Hardcoded/manual |

## Files Modified/Created

- `.zshrc` - Added `code-secrets` function and alias
- `vscode/settings-z-ai.json` - Example VSCode settings (optional)
- `vscode/launch-vscode-with-secrets.sh` - Alternative standalone script

## Next Steps

1. Test the function:
   ```bash
   code-secrets help
   code-secrets .
   ```

2. Verify Claude extension works in VSCode

3. (Optional) Add to your `.zshrc` profile permanently by sourcing from git:
   ```bash
   source "$HOME/dotfiles/shell/.zshrc"
   ```

## Security Notes

- Secrets are only loaded when you explicitly run `code-secrets`
- Secrets exist only in the VSCode process memory
- 1Password CLI requires biometric/password authentication
- Variables are not persisted to disk
