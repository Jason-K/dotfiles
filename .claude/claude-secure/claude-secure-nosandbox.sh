#!/bin/zsh
# Claude wrapper with 1Password secret management using op run
# Single biometric authentication at startup

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

  # Export non-sensitive config vars first
  export Z_AI_MODE="ZAI"
  export Z_WEBSEARCH_URL="https://api.z.ai/api/mcp/web_search_prime/mcp"
  export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
  export API_TIMEOUT_MS="3000000"
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
  export ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.7"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="GLM-4.7"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="GLM-4.5-Air"

  echo "[claude] Starting session with 1Password secrets (one-time authentication)..."

  # Optional debug diagnostics
  if [[ -n "${CLAUDE_SECURE_DEBUG:-}" ]]; then
    echo "[claude][debug] argv: $*" >&2
    if [[ -t 0 ]]; then
      echo "[claude][debug] stdin is a TTY" >&2
    else
      echo "[claude][debug] stdin is NOT a TTY" >&2
    fi
  fi

  # Ensure stdin is a TTY for interactive mode; fall back quietly if unavailable
  local wants_print=0
  for arg in "$@"; do
    if [[ "$arg" == "-p" || "$arg" == "--print" ]]; then
      wants_print=1; break
    fi
  done

  if (( wants_print == 0 )); then
    if ! [[ -t 0 ]]; then
      if [[ -r /dev/tty ]]; then
        exec < /dev/tty
      else
        echo "⚠️  No interactive TTY available. Provide a prompt (-p) or pipe input." >&2
      fi
    fi
  fi

  # Resolve secrets once into the current shell, then run Claude with a real TTY
  local exports
  exports=$(op run --no-masking --env-file="$env_file" -- /usr/bin/printenv \
    | grep -E '^(ANTHROPIC|Z_AI|CONTEXT7|SMITHERY|GITHUB|GEMINI|DEEPSEEK|OPENAI|OPENROUTER)_')
  rc=$?
  if [[ $rc -ne 0 || -z "$exports" ]]; then
    echo "⚠️  Failed to resolve secrets via 1Password (op run)." >&2
    echo "   Continuing WITHOUT injected secrets. Some providers may not work." >&2
    # Best-effort fallback: run Claude without injected secrets so user isn't blocked
    "$claude_bin" "$@"
    rc=$?
    if [[ $rc -ne 0 ]]; then
      echo "❌ claude (fallback) exited with status $rc" >&2
    fi
    return $rc
  fi

  # Export the resolved secrets
  while IFS= read -r line; do
    export "$line"
  done <<< "$exports"

  # Now run Claude directly (keeps interactive TTY intact)
  "$claude_bin" "$@"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "❌ claude-secure exited with status $rc" >&2
  fi
  return $rc
}
