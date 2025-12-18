#!/bin/bash
# Enhanced VSCode wrapper with 1Password secret injection
# This allows VSCode to access Claude extension with z.ai API

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to check if 1Password CLI is available
check_op_installed() {
  if ! command -v op &> /dev/null; then
    echo -e "${RED}[vscode] ERROR: 1Password CLI (op) not found${NC}" >&2
    echo "Install with: brew install 1password-cli" >&2
    return 1
  fi
  return 0
}

# Helper function to load a secret safely
load_secret() {
  local var_name="$1"
  local op_path="$2"
  local value

  value=$(op read "$op_path" 2>/dev/null)
  if [[ -z "$value" ]]; then
    echo -e "${YELLOW}[vscode] WARNING: Failed to load $var_name from 1Password${NC}" >&2
    return 1
  fi

  export "${var_name}=${value}"
  echo -e "${GREEN}[vscode] ✓ Loaded $var_name${NC}"
  return 0
}

# Main VSCode launcher function
vscode-with-secrets() {
  local args=("$@")

  # Check for help
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    cat << 'EOF'
VSCode launcher with 1Password secret injection for Claude extension

USAGE:
  code [file/folder]       Launch VSCode with z.ai secrets for Claude extension
  code help               Show this help message

FEATURES:
  • Automatically loads Z_AI_API_KEY from 1Password
  • Configures Claude extension to use z.ai API endpoint
  • Sets ANTHROPIC_BASE_URL to https://api.z.ai/api/anthropic
  • Injects other API keys (optional)

ENVIRONMENT VARIABLES SET:
  • ANTHROPIC_AUTH_TOKEN  → GLM_API/apikey2
  • Z_AI_API_KEY          → GLM_API/apikey2
  • ANTHROPIC_BASE_URL    → https://api.z.ai/api/anthropic
  • Z_AI_MODE             → ZAI
  • API_TIMEOUT_MS        → 3000000
  • CONTEXT7_API_KEY      → Context7_API/api_key (optional)
  • GITHUB_TOKEN          → GitHub Personal Access Token/token (optional)
  • OPENAI_API_KEY        → oAI_API/api_key2 (optional)

REQUIREMENTS:
  • 1Password CLI: brew install 1password-cli
  • 1Password account with vault named "Secrets"
  • VSCode with Claude extension installed

EXAMPLES:
  code ~/my-project       Open project with secrets loaded
  code .                  Open current directory
  code help               Show this help

EOF
    return 0
  fi

  echo -e "${YELLOW}[vscode] Loading secrets from 1Password...${NC}"

  # Check if op is installed
  check_op_installed || return 1

  # Load required secrets
  load_secret "ANTHROPIC_AUTH_TOKEN" "op://Secrets/GLM_API/apikey2" || {
    echo -e "${RED}[vscode] ERROR: Could not load ANTHROPIC_AUTH_TOKEN${NC}" >&2
    return 1
  }

  load_secret "Z_AI_API_KEY" "op://Secrets/GLM_API/apikey2"

  # Load optional secrets (non-blocking)
  load_secret "CONTEXT7_API_KEY" "op://Secrets/Context7_API/api_key"
  load_secret "SMITHERY_API_KEY" "op://Secrets/Context7_API/api_key"
  load_secret "GITHUB_TOKEN" "op://Secrets/GitHub Personal Access Token/token"
  load_secret "OPENAI_API_KEY" "op://Secrets/oAI_API/api_key2"

  # Map Context7 key to Smithery if only one is present
  if [[ -z "${SMITHERY_API_KEY:-}" && -n "${CONTEXT7_API_KEY:-}" ]]; then
    export SMITHERY_API_KEY="$CONTEXT7_API_KEY"
  fi

  # Set non-secret config variables
  export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
  export Z_AI_MODE="ZAI"
  export API_TIMEOUT_MS="3000000"
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

  echo -e "${GREEN}[vscode] Environment ready. Starting VSCode...${NC}"

  # Launch VSCode - it will inherit all exported variables
  # The 'code' alias points to VSCode; adjust if using 'code-insiders'
  /usr/bin/open -a "Visual Studio Code" "${args[@]}"
}

# Export the function
export -f vscode-with-secrets
export -f check_op_installed
export -f load_secret
