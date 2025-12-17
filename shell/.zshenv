export LANG=en_US.UTF-8
export EDITOR="micro"

# Load git user config from 1Password (non-interactive)
# Note: Both email fields read from "username" field — verify this is intentional
if command -v op &> /dev/null; then
  _git_email=$(op read "op://Secrets/GitHub Personal Access Token/username" 2>/dev/null)
  [[ -n "$_git_email" ]] && export GIT_AUTHOR_EMAIL="$_git_email" GIT_COMMITTER_EMAIL="$_git_email"
  unset _git_email
fi

# Cargo environment (interactive shells only; prevents slowdown for scripts)
if [[ -n $ZSH_VERSION && -t 1 && -r "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi
