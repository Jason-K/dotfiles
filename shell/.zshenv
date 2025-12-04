export LANG=en_US.UTF-8
export EDITOR="micro"

# Load git user config from 1Password (non-interactive)
if command -v op &> /dev/null; then
  export GIT_AUTHOR_EMAIL=$(op read "op://Secrets/GitHub Personal Access Token/username" 2>/dev/null)
  export GIT_COMMITTER_EMAIL=$(op read "op://Secrets/GitHub Personal Access Token/username" 2>/dev/null)
fi

# Only source cargo in interactive zsh TTY sessions
if [[ -n $ZSH_VERSION && -t 1 && -r "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi
