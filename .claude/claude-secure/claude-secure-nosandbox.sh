#!/bin/zsh
# Claude wrapper with 1Password secret management using op run
# Single biometric authentication at startup - NO REPEATED PROMPTS

claude-secure() {
  local claude_bin="$HOME/dotfiles/.claude/local/claude"
  local env_file="$HOME/dotfiles/.claude/claude-secure/.claude-env"
  local rc=0

  if [[ ! -x "$claude_bin" ]]; then
    echo "❌ Claude binary not found: $claude_bin" >&2
    return 1
  fi

  if [[ ! -r "$env_file" ]]; then
    echo "❌ Environment file not found: $env_file" >&2
    return 1
  fi

  # ─────────────────────────────────────────────────────────────────────────
  # 1. NON-SENSITIVE CONFIG
  # ─────────────────────────────────────────────────────────────────────────
  export Z_AI_MODE="ZAI"
  export Z_WEBSEARCH_URL="https://api.z.ai/api/mcp/web_search_prime/mcp"
  export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
  export API_TIMEOUT_MS="3000000"
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
  export ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.7"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="GLM-4.7"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="GLM-4.5-Air"

  # 1Password SSH agent for git operations
  local ssh_auth_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  if [[ -S "$ssh_auth_sock" ]]; then
    export SSH_AUTH_SOCK="$ssh_auth_sock"
  fi

  # ─────────────────────────────────────────────────────────────────────────
  # 2. RESOLVE SECRETS ONCE (skip if already set)
  # ─────────────────────────────────────────────────────────────────────────
  if [[ -z "${ANTHROPIC_API_KEY:-}" || -z "${Z_AI_API_KEY:-}" || -z "${CONTEXT7_API_KEY:-}" ]]; then
    echo "[claude] Resolving secrets from 1Password (one-time biometric auth)..." >&2

    local exports
    exports=$(op run --no-masking --env-file="$env_file" -- /usr/bin/printenv \
      | grep -E '^(ANTHROPIC|Z_AI|CONTEXT7|SMITHERY|GITHUB|GEMINI|DEEPSEEK|OPENAI|OPENROUTER)_')
    rc=$?

    if [[ $rc -ne 0 || -z "$exports" ]]; then
      echo "⚠️  Failed to resolve secrets via 1Password (op run)." >&2
      echo "   Continuing WITHOUT injected secrets. Some providers may not work." >&2
      "$claude_bin" "$@"
      return $?
    fi

    # Export the resolved secrets to current shell
    while IFS= read -r line; do
      export "$line"
    done <<< "$exports"

    echo "[claude] ✅ Secrets resolved" >&2
  else
    echo "[claude] Secrets already in environment, skipping 1Password" >&2
  fi

  # ─────────────────────────────────────────────────────────────────────────
  # 3. BACKFILL AND PREVENT RUNTIME OP CALLS
  # ─────────────────────────────────────────────────────────────────────────
  
  # Backfill related vars
  export Z_AI_API_KEY="${Z_AI_API_KEY:-$ANTHROPIC_API_KEY}"
  export ZAI_API_KEY="${ZAI_API_KEY:-$ANTHROPIC_API_KEY}"
  export SMITHERY_API_KEY="${SMITHERY_API_KEY:-$CONTEXT7_API_KEY}"

  # CRITICAL: Prevent runtime biometric prompts from headersHelper
  export HEADERS_HELPER_MODE="env"
  export HEADERS_HELPER_DISABLE_OP="1"

  # Resolve auth conflict: prefer API key over token
  if [[ -n "${ANTHROPIC_API_KEY:-}" && -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
    unset ANTHROPIC_AUTH_TOKEN
  fi

  # ─────────────────────────────────────────────────────────────────────────
  # 4. TTY HANDLING
  # ─────────────────────────────────────────────────────────────────────────
  local wants_print=0
  for arg in "$@"; do
    if [[ "$arg" == "-p" || "$arg" == "--print" ]]; then
      wants_print=1
      break
    fi
  done

  if (( wants_print == 0 )) && ! [[ -t 0 ]]; then
    if [[ -r /dev/tty ]]; then
      exec < /dev/tty
    else
      echo "⚠️  No interactive TTY available. Use -p/--print or pipe input." >&2
    fi
  fi

  # ─────────────────────────────────────────────────────────────────────────
  # 5. RUN CLAUDE
  # ─────────────────────────────────────────────────────────────────────────
  "$claude_bin" "$@"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "❌ claude-secure exited with status $rc" >&2
  fi
  return $rc
}
