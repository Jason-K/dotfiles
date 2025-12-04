# ==================================================================
# ~/.zprofile — login-shell environment & PATH policy (macOS, zsh)
# ==================================================================

# Locale & editor
export LANG="en_US.UTF-8"
export EDITOR="micro"   # change to nvim if you prefer

# Put Homebrew FIRST on PATH & set related env
if command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Rust / Cargo environment
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# LM Studio CLI
[[ -d "$HOME/.cache/lm-studio/bin" ]] && export PATH="$PATH:$HOME/.cache/lm-studio/bin"

# Optional custom local environment (guarded)
[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# Developer tools
# NOTE: ~/.cargo/bin is already added by sourcing ~/.cargo/env above.
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# GUI app CLIs (only if you actually use them)
export PATH="/Applications/Privileges.app/Contents/MacOS/privilegescli:$PATH"
export PATH="/Applications/CMake.app/Contents/bin:$PATH"
export PATH="/Applications/Little Snitch.app/Contents/Components:$PATH"

# 1Password SSH agent (macOS)
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Homebrew safety knobs
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_NO_ANALYTICS=1

# --- PATH de-dup (zsh) ---
typeset -U path PATH
# --- End of ~/.zprofile ---
