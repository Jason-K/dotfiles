#!/bin/bash
# VSCode Insiders launcher with 1Password secret injection
# This replaces the normal VSCode Insiders app to auto-inject secrets
#
# Install instructions:
# 1. Make this executable: chmod +x ~/dotfiles/vscode/.vscode-launcher.sh
# 2. Create an alias in ~/.zshrc: alias code='~/dotfiles/vscode/.vscode-launcher.sh'
# 3. Or in Spotlight/Cmd+Space, it will run this script instead

# Load secrets from 1Password
export ANTHROPIC_AUTH_TOKEN=$(op read "op://Secrets/GLM_API/apikey2" 2>/dev/null)
export Z_AI_API_KEY=$(op read "op://Secrets/GLM_API/apikey2" 2>/dev/null)
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export Z_AI_MODE="ZAI"
export API_TIMEOUT_MS="3000000"
export CONTEXT7_API_KEY=$(op read "op://Secrets/Context7_API/api_key" 2>/dev/null)
export GITHUB_TOKEN=$(op read "op://Secrets/GitHub Personal Access Token/token" 2>/dev/null)
export OPENAI_API_KEY=$(op read "op://Secrets/oAI_API/api_key2" 2>/dev/null)
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Store secrets in a file VSCode can read
VSCODE_ENV_FILE="$HOME/dotfiles/vscode/.vscode-secrets.env"
cat > "$VSCODE_ENV_FILE" << 'EOF'
ANTHROPIC_AUTH_TOKEN=$ANTHROPIC_AUTH_TOKEN
Z_AI_API_KEY=$Z_AI_API_KEY
ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL
Z_AI_MODE=$Z_AI_MODE
API_TIMEOUT_MS=$API_TIMEOUT_MS
CONTEXT7_API_KEY=$CONTEXT7_API_KEY
GITHUB_TOKEN=$GITHUB_TOKEN
OPENAI_API_KEY=$OPENAI_API_KEY
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=$CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
EOF

# Launch VSCode Insiders with environment variables
exec /usr/bin/open -a "Visual Studio Code - Insiders" "$@"
