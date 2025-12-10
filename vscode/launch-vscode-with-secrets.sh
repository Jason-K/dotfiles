#!/bin/bash
# VSCode launcher that injects 1Password secrets for Claude extension
# Usage: ./launch-vscode-with-secrets.sh [vscode args]

set -e

# Load secrets from 1Password
echo "[vscode-secrets] Loading secrets from 1Password..."

# Read all secrets from 1Password once
export ANTHROPIC_AUTH_TOKEN=$(op read "op://Secrets/GLM_API/apikey2" 2>/dev/null || echo "")
export Z_AI_API_KEY=$(op read "op://Secrets/GLM_API/apikey2" 2>/dev/null || echo "")
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export Z_AI_MODE="ZAI"
export API_TIMEOUT_MS="3000000"

# Optional: Add other secrets needed
export CONTEXT7_API_KEY=$(op read "op://Secrets/Context7_API/api_key" 2>/dev/null || echo "")
export GITHUB_TOKEN=$(op read "op://Secrets/GitHub Personal Access Token/token" 2>/dev/null || echo "")
export OPENAI_API_KEY=$(op read "op://Secrets/oAI_API/api_key2" 2>/dev/null || echo "")

# Verify secrets were loaded
if [[ -z "$Z_AI_API_KEY" ]]; then
  echo "[vscode-secrets] ERROR: Failed to load Z_AI_API_KEY from 1Password" >&2
  exit 1
fi

echo "[vscode-secrets] Secrets loaded successfully."
echo "[vscode-secrets] Starting VSCode..."

# Launch VSCode with inherited environment variables
/usr/bin/open -a "Visual Studio Code" "$@"
