# ==================================================================
# ~/.zshrc — interactive runtime (fast OMZ + zoxide + fzf-tab)
# ==================================================================

# ---- 0) P10k Instant Prompt (MUST be first) ----------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---- 1) Oh My Zsh basic config ----------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# OMZ options
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 1

# ---- 2) Completion cache BEFORE sourcing OMZ ---------------------
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump-${ZSH_VERSION}"
autoload -Uz compinit
zstyle ':completion:*' use-cache on
zstyle ':completion:*' rehash true
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion-cache"
mkdir -p "${ZSH_COMPDUMP:h}"
# Only regenerate compdump once per day for speed
if [[ -n ${ZSH_COMPDUMP}(#qNmh-20) ]]; then
  compinit -C -d "${ZSH_COMPDUMP}"
else
  compinit -d "${ZSH_COMPDUMP}"
fi

# ---- 3) fzf-tab styles (you’re using fzf-tab in place of OMZ fzf)-
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=** r:|=**'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'

# ---- 4) OMZ plugins (trimmed; no duplicates/heavy items) --------
plugins=(
  aliases
  common-aliases
  copyfile
  copypath
  direnv
  extract
  fzf-tab                 # keep; we drop OMZ's fzf plugin
  web-search
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-interactive-cd
  # NOTE: we DON'T use OMZ's zsh-syntax-highlighting (we load fast-syntax-highlighting below)
)

source "$ZSH/oh-my-zsh.sh"   # OMZ will skip compinit because we ran it

# ---- 5) Prompt init (choose one: we keep p10k; Starship disabled) -
[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh
# If you prefer Starship, comment the line above and uncomment below:
# eval "$(starship init zsh)"

# ---- 6) zoxide (standardize; do NOT alias cd or define z/zz) ----
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias j='z'
fi

# ---- 7) fast-syntax-highlighting (faster than OMZ's syntax plugin)
# Install once if missing (guarded, shallow clone)
FAST_HIGHL="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
if [[ ! -d "$FAST_HIGHL" ]]; then
  command -v git >/dev/null 2>&1 && \
    git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$FAST_HIGHL"
fi
# Style tweaks (subtle, readable)
typeset -A FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[command]='fg=green'
FAST_HIGHLIGHT_STYLES[builtin]='fg=blue'
FAST_HIGHLIGHT_STYLES[alias]='fg=cyan'
FAST_HIGHLIGHT_STYLES[function]='fg=cyan'
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=magenta'
FAST_HIGHLIGHT_STYLES[path]='fg=yellow'
FAST_HIGHLIGHT_STYLES[globbing]='fg=magenta'
FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=magenta'
FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=magenta'
FAST_HIGHLIGHT_STYLES[back-quoted-argument]='fg=yellow'
# Load after autosuggestions for correct layering
[[ -r "$FAST_HIGHL/fast-syntax-highlighting.plugin.zsh" ]] && source "$FAST_HIGHL/fast-syntax-highlighting.plugin.zsh"

# ---- 8) Tool inits (light & guarded) -----------------------------
# fzf key bindings/completion (single init; complements fzf-tab)
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)

# Bun completions (guard)
[[ -r "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# fclones completions (guard)
command -v fclones >/dev/null 2>&1 && source <(fclones complete zsh)

# mise activation (guard)
[[ -x "$HOME/.local/bin/mise" ]] && eval "$("$HOME/.local/bin/mise" activate zsh)"

# Conda (only if installed; noisy otherwise)
[[ -x "/opt/anaconda3/bin/conda" ]] && eval "$(/opt/anaconda3/bin/conda shell.zsh hook 2>/dev/null)"

# ---- 9) Key bindings --------------------------------------------
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M menuselect '^M' .accept-line
bindkey '^I' menu-complete
bindkey "$terminfo[kcbt]" reverse-menu-complete
bindkey "^X^_" redo
bindkey "^U" backward-kill-line

# ---- 10) Aliases & helpers (restored + tidy) ---------------------
# Build/Run
alias build='nocorrect build'
alias run='nocorrect run'

# Quick inspectors
alias aliases="alias | sed 's/=.*//'"
alias functions="declare -f | grep '^[a-z].* ()' | sed 's/{$//'"
alias paths='echo -e ${PATH//:/\\n}'

# Directory listings (eza)
alias l="eza -l --icons --git"
alias ls="eza --icons=always --group-directories-first --no-symlinks -x"
alias ll="eza --icons --group-directories-first --no-symlinks -l"
alias la="eza --icons --group-directories-first --no-symlinks -la"
alias lt="eza --icons --tree --level=2"
alias ltree="eza --tree --level=2 --long --icons"

# Folders & nav
alias ..="cd .."
alias ...="cd ../.."
alias docs='cd ~/Documents'
alias dls='cd ~/Downloads'
alias desk='cd ~/Desktop'
alias scripts='cd ~/Scripts'
alias lastdl='open kmtrigger://macro=Open%20most%20recently%20downloaded%20file'

# Fix macOS menu bar weirdness
alias fixmb="rm -rf '$HOME/Library/Group Containers/group.com.apple.controlcenter/Library/Preferences/group.com.apple.controlcenter.plist' && killall ControlCenter"

# Editors & apps
alias cat='bat'
alias nano='micro'
alias code='code-insiders'
alias fz='fzf --preview "bat --style=header --color=always --line-range :50 {}" --preview-window=right:60% | xargs open'

# Network
alias ipp="dig +short myip.opendns.com @resolver1.opendns.com"
alias ipl="ip route get 1.1.1.1 2>/dev/null | awk 'NR==1{print \$7}'"

# Maintenance
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes ~/.Trash; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

# macOS tools (absolute paths)
alias codesign=/usr/bin/codesign
alias stapler='/usr/bin/xcrun stapler'
alias notarytool='/usr/bin/xcrun notarytool'

# Updates
alias update='topgrade'

# Karabiner config rebuild
alias kbuild='nocorrect (cd ~/dotfiles/karabiner/karabiner.ts && npm run build)'

# One reload alias (login-style)
# alias reload='exec "${SHELL}" -l'
alias reload='source ~/.zshrc && echo "Reloaded .zshrc"'

# Yazi smart-cd wrapper
y() {
  local tmp="$(mktemp -t 'yazi-cwd.XXXXXX')" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(<"$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then builtin cd -- "$cwd"; fi
  rm -f -- "$tmp"
}

# ripgrep-all finder with preview (opens via macOS 'open')
fif() {
  [[ "$#" -gt 0 ]] || { echo "Need a search term"; return 1; }
  local file
  file="$(rga --max-count=1 --ignore-case --files-with-matches --no-messages "$*" \
        | fzf-tmux +m --preview="rga --ignore-case --pretty --context 10 '$*' {}")" \
        && echo "opening $file" && open "$file" || return 1
}

# fuzzy cd using locate + fzf
cf() {
  local file
  file="$(locate -Ai -0 "$@" | grep -z -vE '~$' | fzf --read0 -0 -1)"
  [[ -n "$file" ]] || return
  if [[ -d "$file" ]]; then cd -- "$file"; else cd -- "${file:h}"; fi
}

# pick processes and kill
fkill() {
  local pid
  if [[ "$UID" != "0" ]]; then
    pid=$(ps -f -u "$UID" | sed 1d | fzf -m | awk '{print $2}')
  else
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  fi
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -"${1:-9}"
}

# ---- 11) Tool wrappers with varlock secret management ----------

# Open Codex wrapper
alias open_codex="varlock run -- /opt/homebrew/bin/open-codex"
alias open-codex="varlock run -- /opt/homebrew/bin/open-codex"

# Claude wrapper (Varlock with .env.schema)
claude() {
  if ! command -v varlock >/dev/null 2>&1; then
    echo "[claude] 'varlock' not found in PATH" >&2
    return 127
  fi

  # Ensure .env.schema exists in current directory for varlock
  if [[ ! -f .env.schema ]]; then
    # Copy canonical schema from dotfiles
    if [[ -f "$HOME/dotfiles/shell/.env.schema" ]]; then
      cp "$HOME/dotfiles/shell/.env.schema" .env.schema
      echo "[claude] Copied .env.schema to current directory"
    else
      echo "[claude] Warning: .env.schema not found in dotfiles/shell/" >&2
    fi
  fi

  # Ensure .env.schema is in .gitignore
  if [[ -f .gitignore ]]; then
    if ! grep -q "^\.env\.schema$" .gitignore; then
      echo ".env.schema" >> .gitignore
      echo "[claude] Added .env.schema to .gitignore"
    fi
  else
    echo ".env.schema" > .gitignore
    echo "[claude] Created .gitignore with .env.schema"
  fi

  varlock run -- /Users/jason/.claude/local/claude "$@"
}

# Cling helper function
cling() {
  local folders=()
  for arg in "$@"; do
    if [[ -d "$arg" ]]; then
      folders+=("$arg")
    elif [[ -f "$arg" ]]; then
      folders+=("$(dirname "$arg")")
    fi
  done
  [[ ${#folders[@]} -gt 0 ]] && open -a Cling "${folders[@]}"
}

export VARLOCK_TELEMETRY_DISABLED=true

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/jason/.cache/lm-studio/bin"
# End of LM Studio CLI section

# ---- 12) Final niceties & PATH additions ------------------------
# Measure startup quickly: for i in {1..5}; do /usr/bin/time -l zsh -i -c exit; done

# PATH additions (consolidated to reduce duplicate entries)
path=(
  "$HOME/Scripts/Metascripts/hsLauncher/scripts"
  "$HOME/.cache/lm-studio/bin"
  "$HOME/.antigravity/antigravity/bin"
  $path
)
export PATH

# Docker completions (fpath only; compinit already run above)
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

# thefuck alias (guard for speed)
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"

# tv init (guard)
command -v tv >/dev/null 2>&1 && eval "$(tv init zsh)"

# fzf (guard; fallback if not loaded by fzf --zsh above)
[[ ! -v FZF_DEFAULT_OPTS && -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

