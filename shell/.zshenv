export LANG=en_US.UTF-8
export EDITOR="micro"

# Only source cargo in interactive zsh TTY sessions
if [[ -n $ZSH_VERSION && -t 1 && -r "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi