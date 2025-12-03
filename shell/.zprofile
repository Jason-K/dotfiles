# ==================================================================
# ~/.zprofile — login-shell environment & PATH policy (macOS, zsh)
# Keep interactive runtime (aliases, plugins, prompt) in ~/.zshrc
# ==================================================================

# Locale & editor
export LANG="en_US.UTF-8"
export EDITOR="micro"   # change to nvim if you prefer

# Put Homebrew FIRST on PATH & set related env
if command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# (Optional) If you also use MacPorts, put it AFTER Homebrew
# export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# Rust / Cargo environment (adds ~/.cargo/bin, configures env)
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# LM Studio CLI (append once; avoid duplicating later)
[[ -d "$HOME/.cache/lm-studio/bin" ]] && export PATH="$PATH:$HOME/.cache/lm-studio/bin"

# Optional custom local environment (guarded)
[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# Developer tools (append after brew so brew stays first)
# NOTE: ~/.cargo/bin is already added by sourcing ~/.cargo/env above.
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
# If you need a specific Node runtime pinned, uncomment:
# export PATH="$HOME/.nvm/versions/node/v22.14.0/bin:$PATH"

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

# Avoid hard-pinning Python globally unless necessary.
# If you truly need this Python first, guard it and move it AFTER brew:
# if [ -x "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3" ]; then
#   export PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:$PATH"
# fi

# --- PATH de-dup (zsh) ---
# Keep first occurrence, remove subsequent duplicates, preserve order.
typeset -U path PATH

# Keep login profile minimal: no plugin sourcing, no prompt setup here.