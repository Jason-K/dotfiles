#!/bin/zsh
# Claude wrapper with 1Password secret management + subagent setup
# Extracted from ~/.zshrc for modularity

claude-secure() {
  local claude_bin="$HOME/dotfiles/.claude/local/claude"

  # Load secrets from 1Password once and export for all subagents
  echo "[claude] Loading secrets from 1Password (one-time authentication)..."

  # Read all secrets from 1Password once and export them
  # Subagents will inherit these exported environment variables
  export ANTHROPIC_AUTH_TOKEN=$(op read "op://Secrets/GLM_API/apikey2" 2>/dev/null)
  export Z_AI_API_KEY=$(op read "op://Secrets/GLM_API/apikey2" 2>/dev/null)
  export CONTEXT7_API_KEY=$(op read "op://Secrets/Context7_API/api_key" 2>/dev/null)
  export GITHUB_TOKEN=$(op read "op://Secrets/GitHub Personal Access Token/token" 2>/dev/null)
  export GEMINI_API_KEY=$(op read "op://Secrets/Gemini_API/api_key" 2>/dev/null)
  export DEEPSEEK_API_KEY=$(op read "op://Secrets/Deepseek_API/api_key" 2>/dev/null)
  export OPENAI_API_KEY=$(op read "op://Secrets/oAI_API/api_key2" 2>/dev/null)
  export OPENROUTER_API_KEY=$(op read "op://Secrets/OpenRouter_API/api_key" 2>/dev/null)
  export SMITHERY_API_KEY=$(op read "op://Secrets/Smithery/credential" 2>/dev/null)

  # Export non-sensitive config vars
  export Z_AI_MODE="ZAI"
  export Z_WEBSEARCH_URL="https://api.z.ai/api/mcp/web_search_prime/mcp"
  export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
  export API_TIMEOUT_MS="3000000"
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
  export ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.6"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="GLM-4.6"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="GLM-4.5-Air"

  echo "[claude] Environment loaded. Starting Claude..."

  # Run Claude directly - it inherits all exported environment variables
  "$claude_bin" "$@"
}
