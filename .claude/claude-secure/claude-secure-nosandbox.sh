#!/bin/zsh
# Claude wrapper with 1Password secret management + subagent setup
# Extracted from ~/.zshrc for modularity

claude-secure() {
  local claude_bin="$HOME/dotfiles/.claude/local/claude"

  # Handle special commands (these don't require secrets or running Claude)
  case "${1:-}" in
    "setup")
      # Initialize claude for current project with subagent selection
      if [[ ! -d .claude ]]; then
        echo "[claude] Initializing .claude directory for this project..."
        mkdir -p .claude/{agents,tmp}
        echo "[claude] Created .claude directory structure"
      fi
      # Run interactive subagent setup
      "$HOME/dotfiles/shell/claude-setup.sh"
      return $?
      ;;
    "list-agents")
      # List available agents from registry
      if [[ ! -d "$HOME/dotfiles/.claude/subagents-registry/categories" ]]; then
        echo "[claude] Subagents registry not found at ~/.claude/subagents-registry" >&2
        return 1
      fi
      echo "[claude] Available Agent Categories:"
      echo ""
      find "$HOME/dotfiles/.claude/subagents-registry/categories" -maxdepth 1 -type d | sort | while read -r cat_dir; do
        if [[ "$cat_dir" != "$HOME/dotfiles/.claude/subagents-registry/categories" ]]; then
          local cat_name=$(basename "$cat_dir")
          local agent_count=$(find "$cat_dir" -maxdepth 1 -name "*.md" ! -name "README.md" | wc -l)
          printf "  %-35s (%2d agents)\n" "$cat_name" "$agent_count"
        fi
      done
      return 0
      ;;
    "help"|"--help"|"-h")
      # Show enhanced help (don't pass to Claude for these)
      cat << 'EOF'

Claude command-line interface with subagent setup

USAGE:
  claude [command] [args]

COMMANDS:
  setup                    Interactive setup to add subagents to .claude/agents/
  list-agents             List all available agent categories
  help, --help, -h        Show this help message
  (any other args)        Pass through to Claude CLI

EXAMPLES:
  claude setup            # Start interactive subagent selection
  claude list-agents      # Show available agent categories
  claude --help-native    # Show Claude's built-in help
  claude @project-context # Use Claude with project context

SUBAGENT SETUP:
  When you run 'claude setup', you'll be guided through:
  1. Browse agent categories
  2. Select agents for your project
  3. Agents are installed to .claude/agents/

The setup creates a local .claude folder structure if needed.

EOF
      return 0
      ;;
  esac

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
