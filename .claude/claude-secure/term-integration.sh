# iTerm2 Claude Smart Integration v2
# Single biometric auth - no repeated prompts
# Source this from ~/.zshrc

# ─────────────────────────────────────────────────────────────────────────────
# PATHS
# ─────────────────────────────────────────────────────────────────────────────
CLAUDE_SECURE_DIR="$HOME/dotfiles/.claude/claude-secure"
CLAUDE_LAUNCHER="$CLAUDE_SECURE_DIR/claude-launcher.sh"
CLAUDE_DOCKER_SCRIPT="$CLAUDE_SECURE_DIR/claude-docker.sh"
CLAUDE_WRAPPER="$CLAUDE_SECURE_DIR/claude-secure-wrapper.sh"
CLAUDE_SMART="$CLAUDE_SECURE_DIR/claude-smart-simple"
CLAUDE_ENV_FILE="$CLAUDE_SECURE_DIR/.claude-env"

# ─────────────────────────────────────────────────────────────────────────────
# DOCKER: Secure Container (RECOMMENDED)
# ─────────────────────────────────────────────────────────────────────────────

claude-docker() {
    if [[ ! -x "$CLAUDE_DOCKER_SCRIPT" ]]; then
        echo "❌ Claude Docker script not found: $CLAUDE_DOCKER_SCRIPT" >&2
        return 1
    fi

    # Pre-resolve secrets before calling docker script
    _claude_resolve_secrets || return 1

    "$CLAUDE_DOCKER_SCRIPT" "$@"
}

alias cdocker='claude-docker'


# ─────────────────────────────────────────────────────────────────────────────
# CORE: Single auth then launch
# ─────────────────────────────────────────────────────────────────────────────

# Main launcher with secrets (RECOMMENDED)
claude() {
    if [[ ! -x "$CLAUDE_LAUNCHER" ]]; then
        echo "❌ Claude launcher not found: $CLAUDE_LAUNCHER" >&2
        return 1
    fi
    "$CLAUDE_LAUNCHER" "$@"
}

# Alias for convenience
alias cs='claude'

# ─────────────────────────────────────────────────────────────────────────────
# SMART: Auto-detect project preset with sandbox
# ─────────────────────────────────────────────────────────────────────────────

claude-smart() {
    if [[ ! -x "$CLAUDE_SMART" ]]; then
        echo "❌ Claude smart script not found: $CLAUDE_SMART" >&2
        return 1
    fi

    # Pre-resolve secrets before calling wrapper
    _claude_resolve_secrets || return 1

    "$CLAUDE_SMART" "$@"
}

# Quick aliases for smart mode
alias c='claude-smart'
alias cl='claude-smart'

# ─────────────────────────────────────────────────────────────────────────────
# DESKTOP AUTH: Use Claude Desktop credentials (no env injection)
# ─────────────────────────────────────────────────────────────────────────────

claude-desktop() {
    if [[ ! -x "$CLAUDE_SMART" ]]; then
        echo "❌ Claude smart script not found: $CLAUDE_SMART" >&2
        return 1
    fi

    # Switch auth mode to desktop: wrapper will avoid op/env injection
    export CLAUDE_AUTH_MODE="desktop"
    export ANTHROPIC_BASE_URL="https://api.anthropic.com"
    # Ensure headersHelper does not attempt op reads
    export HEADERS_HELPER_MODE="env"
    export HEADERS_HELPER_DISABLE_OP="1"

    # Fallback: if no Desktop session env exists, use env-mode secrets
    local session_dir="$HOME/.claude/session-env"
    local has_session=0
    if [[ -d "$session_dir" ]]; then
        # consider presence of any *.env file as session availability
        local envs=("$session_dir"/*.env(N))
        (( ${#envs[@]} > 0 )) && has_session=1
    fi
    if (( has_session == 0 )); then
        echo "⚠️  No Claude Desktop session env found; falling back to env-mode secrets" >&2
        export CLAUDE_AUTH_MODE="env"
        _claude_resolve_secrets || return 1
        # restore z.ai defaults expected by env mode
        export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.z.ai/api/anthropic}"
        export Z_AI_MODE="${Z_AI_MODE:-ZAI}"
    fi

    "$CLAUDE_SMART" "$@"
}

# Quick alias without colliding with built-in `cd`
alias cdesk='claude-desktop'

# ─────────────────────────────────────────────────────────────────────────────
# DIAGNOSTIC: Check Claude Desktop session env availability
# ─────────────────────────────────────────────────────────────────────────────

claude-desktop-status() {
    local session_dir="$HOME/.claude/session-env"
    if [[ ! -d "$session_dir" ]]; then
        echo "❌ No Claude Desktop session env directory: $session_dir" >&2
        echo "   Ensure Claude Desktop is installed and signed in." >&2
        return 1
    fi

    local envs=("$session_dir"/*.env(N))
    if (( ${#envs[@]} == 0 )); then
        echo "⚠️  No session env files found under: $session_dir" >&2
        return 1
    fi

    echo "🖥️ Claude Desktop session env files:" >&2
    for envf in "${envs[@]}"; do
        echo "  - ${envf:t}" >&2
        for key in ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY Z_AI_API_KEY ZAI_API_KEY CLAUDE_API_KEY; do
            local val
            val=$(grep -E "^$key=" "$envf" | tail -n1 | cut -d= -f2-)
            if [[ -n "$val" ]]; then
                echo "    $key=set(len=${#val})" >&2
            else
                echo "    $key=unset" >&2
            fi
        done
    done
    echo "Base URL: ${ANTHROPIC_BASE_URL:-<unset>}" >&2
}

# Short alias
alias cds='claude-desktop-status'

# ─────────────────────────────────────────────────────────────────────────────
# SANDBOX: Explicit preset selection
# ─────────────────────────────────────────────────────────────────────────────

claude-sandbox() {
    local config="$CLAUDE_SECURE_DIR/projects.toml"

    if [[ $# -lt 1 ]]; then
        cat >&2 << 'EOF'
Usage: claude-sandbox <preset> [args...]

Available presets:
EOF
        grep '^\[' "$config" 2>/dev/null | sed 's/^\[\(.*\)\].*/  - \1/' >&2
        return 1
    fi

    local preset="$1"
    shift

    # Pre-resolve secrets
    _claude_resolve_secrets || return 1

    "$CLAUDE_WRAPPER" \
        --config "$config" \
        --preset "$preset" \
        -- "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
# HELPER: Resolve secrets once (call before any wrapper)
# ─────────────────────────────────────────────────────────────────────────────

_claude_resolve_secrets() {
    # Skip if already resolved
    if [[ -n "${ANTHROPIC_API_KEY:-}" && -n "${Z_AI_API_KEY:-}" && -n "${CONTEXT7_API_KEY:-}" ]]; then
        return 0
    fi

    if [[ ! -r "$CLAUDE_ENV_FILE" ]]; then
        echo "❌ Environment file not found: $CLAUDE_ENV_FILE" >&2
        return 1
    fi

    if ! command -v op &>/dev/null; then
        echo "❌ 1Password CLI (op) not found" >&2
        return 1
    fi

    echo "🔐 Resolving secrets from 1Password (one-time auth)..." >&2

    local exports
    exports=$(op run --no-masking --env-file="$CLAUDE_ENV_FILE" -- /usr/bin/printenv 2>/dev/null \
        | grep -E '^(ANTHROPIC|Z_AI|CONTEXT7|SMITHERY|GITHUB|GEMINI|DEEPSEEK|OPENAI|OPENROUTER)_') || {
        echo "⚠️  Failed to resolve secrets from 1Password" >&2
        return 1
    }

    # Export to current shell
    while IFS= read -r line; do
        [[ -n "$line" ]] && export "$line"
    done <<< "$exports"

    # Backfill related vars
    export Z_AI_API_KEY="${Z_AI_API_KEY:-$ANTHROPIC_API_KEY}"
    export ZAI_API_KEY="${ZAI_API_KEY:-$ANTHROPIC_API_KEY}"
    export SMITHERY_API_KEY="${SMITHERY_API_KEY:-$CONTEXT7_API_KEY}"

    # Prevent any runtime op calls
    export HEADERS_HELPER_MODE="env"
    export HEADERS_HELPER_DISABLE_OP="1"

    echo "✅ Secrets resolved" >&2
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# ITERM2 ENHANCEMENTS
# ─────────────────────────────────────────────────────────────────────────────

if [[ -n "${ITERM_SESSION_ID:-}" ]]; then
    iterm2_print_user_vars() {
        iterm2_set_user_var claudeProject "$(pwd)"
    }
fi

# ─────────────────────────────────────────────────────────────────────────────
# HELP
# ─────────────────────────────────────────────────────────────────────────────

claude-help() {
    cat <<'EOF'
✅ Claude Smart Integration v2

📋 Commands:
   claude [args]                 → Main launcher with secrets (recommended)
   claude-smart [args]           → Smart sandbox (auto-detect preset)
   claude-sandbox <preset> [args] → Explicit preset sandbox
    claude-desktop [args]         → Use Claude Desktop credentials (no env injection)

📝 Aliases:
   c, cl  → claude-smart
   cs     → claude
    cdesk  → claude-desktop

🔐 Secrets are resolved ONCE via 1Password at first invocation.
   Subsequent calls reuse the exported environment variables.

🖥️ Desktop Auth:
    Use `claude-desktop` to avoid z.ai env injection and authenticate
    via the Claude Desktop session. Ensure Claude Desktop is signed in
    and has created session env files under ~/.claude/session-env.
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# COMPLETIONS
# ─────────────────────────────────────────────────────────────────────────────

if command -v compdef &>/dev/null; then
    _claude_opts() {
        local -a options
        options=(
            '--dangerously-skip-permissions[Skip workspace trust dialog]'
            '--print[Print response and exit]'
            '--help[Show help]'
            '--version[Show version]'
            '--continue[Continue last conversation]'
            '--resume[Resume conversation]'
        )
        _describe 'claude options' options
    }

    _claude_sandbox_preset() {
        local presets
        presets=$(grep '^\[' "$CLAUDE_SECURE_DIR/projects.toml" 2>/dev/null | sed 's/^\[\(.*\)\].*/\1/')
        compadd - $presets
    }

    compdef _claude_opts claude
    compdef _claude_opts claude-smart
    compdef _claude_opts c
    compdef _claude_opts cl
    compdef _claude_opts cs
    compdef _claude_opts claude-desktop
    compdef _claude_opts cdesk
    compdef _claude_opts claude-desktop-status
    compdef _claude_opts cds
    compdef _claude_sandbox_preset claude-sandbox
fi
