#!/bin/zsh
# claude-secure-launcher.sh
# Single biometric auth at startup, exports secrets for all child processes
# Patches .claude.json mcpServers to remove op:// fallbacks

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ENV_FILE="$SCRIPT_DIR/.claude-env"
CLAUDE_BIN="$HOME/dotfiles/.claude/local/claude"
CLAUDE_JSON="$HOME/.claude.json"

log() { print -ru2 -- "[claude-secure] $*"; }
die() { log "ERROR: $*"; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# 1. RESOLVE SECRETS ONCE VIA OP RUN
# ─────────────────────────────────────────────────────────────────────────────
resolve_secrets() {
    if [[ -n "${ANTHROPIC_API_KEY:-}" && -n "${Z_AI_API_KEY:-}" && -n "${CONTEXT7_API_KEY:-}" ]]; then
        log "Secrets already in environment, skipping 1Password"
        return 0
    fi

    if [[ ! -r "$ENV_FILE" ]]; then
        die "Environment file not found: $ENV_FILE"
    fi

    if ! command -v op &>/dev/null; then
        die "1Password CLI (op) not found"
    fi

    log "Resolving secrets from 1Password (one-time biometric auth)..."
    
    local exports
    exports=$(op run --no-masking --env-file="$ENV_FILE" -- /usr/bin/printenv 2>/dev/null \
        | grep -E '^(ANTHROPIC|Z_AI|CONTEXT7|SMITHERY|GITHUB|GEMINI|DEEPSEEK|OPENAI|OPENROUTER)_') || {
        die "Failed to resolve secrets via 1Password"
    }

    # Export each resolved secret
    while IFS= read -r line; do
        [[ -n "$line" ]] && export "$line"
    done <<< "$exports"

    # Backfill related vars
    export Z_AI_API_KEY="${Z_AI_API_KEY:-$ANTHROPIC_API_KEY}"
    export ZAI_API_KEY="${ZAI_API_KEY:-$ANTHROPIC_API_KEY}"
    export SMITHERY_API_KEY="${SMITHERY_API_KEY:-$CONTEXT7_API_KEY}"

    log "Secrets resolved: ANTHROPIC_API_KEY=set(${#ANTHROPIC_API_KEY}) Z_AI_API_KEY=set(${#Z_AI_API_KEY}) CONTEXT7_API_KEY=set(${#CONTEXT7_API_KEY})"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. PATCH .CLAUDE.JSON MCP CONFIGS (remove op:// fallbacks)
# ─────────────────────────────────────────────────────────────────────────────
patch_mcp_configs() {
    if [[ ! -f "$CLAUDE_JSON" ]]; then
        log "No .claude.json found, skipping MCP patch"
        return 0
    fi

    # Check if patching is needed (look for op read in headersHelper)
    if ! grep -q 'op read' "$CLAUDE_JSON" 2>/dev/null; then
        return 0
    fi

    log "Patching mcpServers to remove op:// fallbacks..."

    # Use Python for reliable JSON manipulation
    python3 - "$CLAUDE_JSON" <<'PYTHON'
import sys, json, re

path = sys.argv[1]
with open(path, 'r') as f:
    data = json.load(f)

modified = False
mcp = data.get('mcpServers', {})

for name, cfg in mcp.items():
    if 'headersHelper' in cfg:
        old = cfg['headersHelper']
        # Remove op read fallbacks: ${VAR:-$(op read ...)} -> $VAR
        # Pattern: KEY="${VAR:-$(op read '...' 2>/dev/null)}"; -> just use $VAR directly
        new = re.sub(
            r'KEY="\$\{([A-Z_]+):-\$\(op read [^)]+\)\}"\s*;\s*printf\s+',
            r'printf ',
            old
        )
        new = new.replace('$KEY', '${\\1}').replace('${\\1}', '$' + re.search(r'\$\{([A-Z_]+)', old).group(1) if re.search(r'\$\{([A-Z_]+)', old) else '$KEY')
        
        # Simpler approach: just replace the whole thing
        if 'Z_AI_API_KEY' in old:
            new = 'printf \'{"Authorization":"Bearer %s","Accept":"application/json, text/event-stream"}\' "$Z_AI_API_KEY"'
        elif 'CONTEXT7_API_KEY' in old:
            new = 'printf \'{"Authorization":"Bearer %s"}\' "$CONTEXT7_API_KEY"'
        
        if new != old:
            cfg['headersHelper'] = new
            modified = True
            print(f"  Patched: {name}", file=sys.stderr)

    # Handle stdio MCP servers with inline op read
    if cfg.get('type') == 'stdio' and 'args' in cfg:
        args = cfg['args']
        for i, arg in enumerate(args):
            if isinstance(arg, str) and 'op read' in arg:
                # Replace inline op read with env var reference
                new_arg = re.sub(r"\$\(op read '[^']+' 2>/dev/null[^)]*\)", '${Z_AI_API_KEY}', arg)
                if new_arg != arg:
                    args[i] = new_arg
                    modified = True
                    print(f"  Patched stdio args: {name}", file=sys.stderr)

if modified:
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)
    print("MCP configs patched successfully", file=sys.stderr)
PYTHON
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. SET UP ENVIRONMENT
# ─────────────────────────────────────────────────────────────────────────────
setup_environment() {
    # Non-sensitive config
    export Z_AI_MODE="${Z_AI_MODE:-ZAI}"
    export Z_WEBSEARCH_URL="${Z_WEBSEARCH_URL:-https://api.z.ai/api/mcp/web_search_prime/mcp}"
    export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
    export API_TIMEOUT_MS="${API_TIMEOUT_MS:-3000000}"
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-GLM-4.7}"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-GLM-4.7}"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-GLM-4.5-Air}"

    # Prevent runtime biometric prompts
    export HEADERS_HELPER_MODE="env"
    export HEADERS_HELPER_DISABLE_OP="1"

    # 1Password SSH agent for git
    local ssh_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    [[ -S "$ssh_sock" ]] && export SSH_AUTH_SOCK="$ssh_sock"

    # Resolve auth conflict: prefer API key
    if [[ -n "${ANTHROPIC_API_KEY:-}" && -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        unset ANTHROPIC_AUTH_TOKEN
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. TTY HANDLING
# ─────────────────────────────────────────────────────────────────────────────
ensure_tty() {
    local wants_print=0
    for arg in "$@"; do
        [[ "$arg" == "-p" || "$arg" == "--print" ]] && wants_print=1 && break
    done

    if (( wants_print == 0 )) && ! [[ -t 0 ]]; then
        if [[ -r /dev/tty ]]; then
            exec < /dev/tty
        else
            log "WARNING: No interactive TTY available"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
    [[ -x "$CLAUDE_BIN" ]] || die "Claude binary not found: $CLAUDE_BIN"

    resolve_secrets
    setup_environment
    patch_mcp_configs
    ensure_tty "$@"

    log "Launching Claude..."
    exec "$CLAUDE_BIN" "$@"
}

main "$@"
