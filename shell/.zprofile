# ==================================================================
# ~/.zprofile — login-shell environment & PATH policy (macOS, zsh)
# ==================================================================

# Locale (EDITOR is set in .zshenv for consistency)
export LANG="en_US.UTF-8"

# Put Homebrew FIRST on PATH & set related env
if command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Optional custom local environment (guarded)
[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# ---- Consolidated PATH array setup ----
# Note: Cargo is handled in .zshenv only for interactive shells
path=(
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/go/bin"
  "$HOME/Scripts/Metascripts/hsLauncher/scripts"
  $path
)

# GUI app CLIs (guard: only add if they exist)
[[ -d "/Applications/Privileges.app/Contents/MacOS" ]] && path+=("/Applications/Privileges.app/Contents/MacOS/privilegescli")
[[ -d "/Applications/CMake.app/Contents/bin" ]] && path+=("/Applications/CMake.app/Contents/bin")
[[ -d "/Applications/Little Snitch.app/Contents/Components" ]] && path+=("/Applications/Little Snitch.app/Contents/Components")

# Export consolidated PATH
export PATH

# 1Password SSH agent (macOS) — guard for safety
SSH_AUTH_SOCK_PATH="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
[[ -S "$SSH_AUTH_SOCK_PATH" ]] && export SSH_AUTH_SOCK="$SSH_AUTH_SOCK_PATH"

# Homebrew safety knobs
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_NO_ANALYTICS=1

# PATH de-duplication (remove duplicates while preserving order)
typeset -U path PATH

# --- End of ~/.zprofile ---

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
