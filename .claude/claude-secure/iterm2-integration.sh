# iTerm2 Claude Smart Integration
# Add this to your ~/.zshrc or ~/.bashrc

# Create shell function for easy access
claude() {
    local script_path="/Users/jason/dotfiles/.claude/claude-secure/claude-smart-simple"

    # Check if the smart script exists
    if [[ ! -x "$script_path" ]]; then
        echo "❌ Claude smart script not found: $script_path" >&2
        echo "Please ensure the script exists and is executable." >&2
        return 1
    fi

    # Execute the smart script with all arguments
    "$script_path" "$@"
}

# Create iTerm2 shell integration trigger
# This adds a right-click menu option and keyboard shortcut

if [[ -n "${ITERM_SESSION_ID:-}" ]]; then
    # iTerm2-specific enhancements

    # Add to iTerm2 shell integrations
    iterm2_print_user_vars() {
        iterm2_set_user_var claudeProject "$(pwd)"
    }

    # Create a function that can be called from iTerm2 triggers
    claude_in_current_dir() {
        echo "🚀 Launching Claude in: $(pwd)" >&2
        claude --dangerously-skip-permissions "$@"
    }
fi

# Aliases for convenience
alias c='claude'
alias cl='claude'
alias claude-yolo='claude --dangerously-skip-permissions'
alias claude-safe='claude --permission-mode default'

# Auto-completion for zsh
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

    compdef _claude_smart claude
    compdef _claude_smart c
    compdef _claude_smart cl
fi

echo "✅ Claude Smart Integration loaded"
echo "📝 Usage: claude [args] or c [args]"
