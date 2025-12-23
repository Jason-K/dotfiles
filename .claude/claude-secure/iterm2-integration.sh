# iTerm2 Claude Smart Integration
# Provides vanilla Claude and intelligent sandboxed access

# ───────────────────────────────────────────────────────────────────────────────
# 1) Vanilla Claude (no wrapper, no secrets, no sandbox)
# ───────────────────────────────────────────────────────────────────────────────

claude() {
    local claude_bin="$HOME/dotfiles/.claude/local/claude"

    if [[ ! -x "$claude_bin" ]]; then
        echo "❌ Claude binary not found: $claude_bin" >&2
        return 1
    fi

    # Run vanilla Claude with no modifications
    echo "🚀 Launching vanilla Claude..." >&2
    "$claude_bin" "$@"
}

# ───────────────────────────────────────────────────────────────────────────────
# 2) Smart launcher with preset detection & sandboxing
# ───────────────────────────────────────────────────────────────────────────────

# Intelligent sandbox: detects presets from projects.toml, creates temp sandboxes
claude-smart() {
    local script_path="/Users/jason/dotfiles/.claude/claude-secure/claude-smart-simple"

    if [[ ! -x "$script_path" ]]; then
        echo "❌ Claude smart script not found: $script_path" >&2
        return 1
    fi

    "$script_path" "$@"
}

# ───────────────────────────────────────────────────────────────────────────────
# 3) Secrets-enabled direct run (no sandbox): loads secrets then runs Claude
# ───────────────────────────────────────────────────────────────────────────────

# Non-sandboxed Claude with 1Password secrets (one-time biometric auth via op run)
claude-secrets() {
    local secrets_script="$HOME/dotfiles/.claude/claude-secure/claude-secure-nosandbox.sh"

    if [[ ! -r "$secrets_script" ]]; then
        echo "❌ Secrets launcher not found: $secrets_script" >&2
        return 1
    fi

    # Source once to load the claude-secure helper, then invoke it
    # This keeps the secrets-loading logic in a single place.
    source "$secrets_script"

    if ! command -v claude-secure >/dev/null 2>&1; then
        echo "❌ claude-secure function unavailable after sourcing: $secrets_script" >&2
        return 1
    fi

    claude-secure "$@"
}

# ───────────────────────────────────────────────────────────────────────────────
# 4) Sandbox wrapper (advanced): call claude-secure-wrapper directly
# ───────────────────────────────────────────────────────────────────────────────

# Direct wrapper access with explicit config/preset (for advanced usage)
claude-sandbox() {
    local config="$HOME/dotfiles/.claude/claude-secure/projects.toml"

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

    "$HOME/dotfiles/.claude/claude-secure/claude-secure-wrapper.sh" \
        --config "$config" \
        --preset "$preset" \
        -- "$@"
}

# ───────────────────────────────────────────────────────────────────────────────
# 4) iTerm2 enhancements
# ───────────────────────────────────────────────────────────────────────────────

if [[ -n "${ITERM_SESSION_ID:-}" ]]; then
    # iTerm2-specific shell integration
    iterm2_print_user_vars() {
        iterm2_set_user_var claudeProject "$(pwd)"
        iterm2_set_user_var claudeMode "smart"  # default to smart/sandbox
    }

    # Launch Claude smart mode (sandboxed) in current directory
    claude_in_current_dir() {
        echo "🚀 Launching Claude (smart sandbox) in: $(pwd)" >&2
        claude-smart --dangerously-skip-permissions "$@"
    }
fi

# ───────────────────────────────────────────────────────────────────────────────
# 5) Aliases for convenience
# ───────────────────────────────────────────────────────────────────────────────

# Smart/sandbox mode aliases (primary workflow)
alias c='claude-smart'
alias cl='claude-smart'
alias cs='claude-secrets'

# ───────────────────────────────────────────────────────────────────────────────
# 6) Auto-completion for zsh
# ───────────────────────────────────────────────────────────────────────────────

if command -v compdef >/dev/null 2>&1; then
    _claude_smart() {
        local -a options
        options=(
            '--dangerously-skip-permissions[Skip workspace trust dialog]'
            '--print[Print response and exit]'
            '--help[Show help]'
            '--version[Show version]'
            '--continue[Continue last conversation]'
            '--resume[Resume conversation]'
        )
        _describe 'claude commands' options
    }

    _claude_sandbox_preset() {
        local presets
        presets=$(grep '^\[' "$HOME/dotfiles/.claude/claude-secure/projects.toml" 2>/dev/null | sed 's/^\[\(.*\)\].*/\1/')
        compadd - $presets
    }

    compdef _claude_smart claude
    compdef _claude_smart claude-smart
    compdef _claude_smart c
    compdef _claude_smart cl
    compdef _claude_sandbox_preset claude-sandbox
fi

# ───────────────────────────────────────────────────────────────────────────────
# Optional startup message (disabled by default to avoid P10k instant prompt I/O)
# Enable by exporting CLAUDE_STARTUP_BANNER=1 in your shell env.
# ───────────────────────────────────────────────────────────────────────────────

if [[ -n "${CLAUDE_STARTUP_BANNER:-}" ]]; then
    echo "✅ Claude Smart Integration loaded"
    echo "📋 Available commands:"
    echo "   claude [args]                 → Vanilla Claude (no wrapper, no sandbox)"
    echo "   claude-smart [args]           → Smart sandbox (auto-detect preset)"
    echo "   claude-sandbox <preset> [args] → Explicit preset sandbox"
    echo "📝 Quick aliases: c, cl → claude-smart (safe by default)"
fi

# On-demand help: prints the same banner without affecting shell startup
claude-help() {
    cat <<'EOF'
✅ Claude Smart Integration loaded
📋 Available commands:
   claude [args]                 → Vanilla Claude (no wrapper, no sandbox)
   claude-smart [args]           → Smart sandbox (auto-detect preset)
   claude-sandbox <preset> [args] → Explicit preset sandbox
📝 Quick aliases: c, cl → claude-smart (safe by default)
EOF
}
