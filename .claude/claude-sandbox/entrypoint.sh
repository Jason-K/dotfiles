#!/bin/bash
set -e

# setup_config - Generates Claude Code config from environment variables
# Setup Config Function
setup_config() {
    local api_key="${ANTHROPIC_API_KEY:-$Z_AI_API_KEY}"
    local base_url="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
    
    if [ -z "$api_key" ]; then
        echo "Warning: No API key found (ANTHROPIC_API_KEY or Z_AI_API_KEY)"
    fi

    local z_ai_key="${Z_AI_API_KEY:-$api_key}"
    local context7_key="${CONTEXT7_API_KEY:-}"
    local mode="${Z_AI_MODE:-ZAI}"

    mkdir -p /home/node/.claude
    mkdir -p /home/node/.config/claude-code
    
    # Define config content
    cat > /home/node/.claude/config.json <<EOF
{
  "primaryApiKey": "$api_key",
  "anthropicBaseUrl": "$base_url",
  "hasCompletedOnboarding": true,
  "agreedToTerms": true,
  "verbose": true,
  "disableTelemetry": true,
  "mcpServers": {
    "zai-mcp-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@z_ai/mcp-server"],
      "env": {
        "Z_AI_API_KEY": "$z_ai_key",
        "Z_AI_MODE": "$mode"
      }
    },
    "web-search-prime": {
      "type": "http",
      "url": "https://api.z.ai/api/mcp/web_search_prime/mcp",
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\",\"Accept\":\"application/json, text/event-stream\"}' \"$z_ai_key\""
    },
    "web-reader": {
      "type": "http",
      "url": "https://api.z.ai/api/mcp/web_reader/mcp",
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\",\"Accept\":\"application/json, text/event-stream\"}' \"$z_ai_key\""
    },
    "zai-read": {
      "type": "http",
      "url": "https://api.z.ai/api/mcp/zread/mcp",
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\",\"Accept\":\"application/json, text/event-stream\"}' \"$z_ai_key\""
    },
    "context7-mcp": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headersHelper": "printf '{\"Authorization\":\"Bearer %s\"}' \"$context7_key\""
    }
  }
}
EOF
    # Copy to all possible locations to be safe
    cp /home/node/.claude/config.json /home/node/.claude.json
    cp /home/node/.claude/config.json /home/node/.config/claude-code/config.json
    
    # Ensure they are readable/writable by current user
    chmod 600 /home/node/.claude/config.json
    
    echo "Configured Z.AI endpoint + MCP servers."
    echo "Configuration written to:"
    ls -l /home/node/.claude/config.json
    
    echo "Symlink Verification:"
    ls -ld /Users/jason/.claude || echo "Failed to list /Users/jason/.claude"
}

setup_config

# If ANTHROPIC_MODEL is set, append it to args
CMD_ARGS=("$@")
if [ -n "${ANTHROPIC_MODEL:-}" ]; then
    echo "Using Model: $ANTHROPIC_MODEL"
    CMD_ARGS=("--model" "$ANTHROPIC_MODEL" "${CMD_ARGS[@]}")
fi

exec claude "${CMD_ARGS[@]}" --dangerously-skip-permissions
