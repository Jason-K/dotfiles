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

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 1

# ---- 2) Completion cache BEFORE sourcing OMZ ---------------------
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump-${ZSH_VERSION}"
autoload -Uz compinit
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion-cache"
mkdir -p "${ZSH_COMPDUMP:h}"
# Only regenerate compdump once per day for speed
if [[ -n ${ZSH_COMPDUMP}(#qNmh-20) ]]; then
  compinit -C -d "${ZSH_COMPDUMP}"
else
  compinit -d "${ZSH_COMPDUMP}"
fi

# ---- 3) fzf-tab styles (you’re using fzf-tab in place of OMZ fzf)-

# Case-insensitive completion and fuzzy matching for hidden files, dots, and dashes
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=** r:|=**'
# Preview directories with eza when completing cd commands
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# Don't sort git branches; preserve order for faster selection
zstyle ':completion:*:git-checkout:*' sort false
# Format completion descriptions with brackets
zstyle ':completion:*:descriptions' format '[%d]'
# Use LS_COLORS for file/directory completion coloring
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Don't show menu completion by default (we use fzf-tab instead)
zstyle ':completion:*' menu no
# Customize fzf colors and keybindings for fzf-tab completion
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# Use fzf default options (respects $FZF_DEFAULT_OPTS)
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# Allow '<' and '>' to switch between completion groups
zstyle ':fzf-tab:*' switch-group '<' '>'

# ---- 4) OMZ plugins (trimmed; no duplicates/heavy items) --------

plugins=(
  aliases
  copyfile
  copypath
  direnv
  extract
  fzf-tab
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-interactive-cd
)

source "$ZSH/oh-my-zsh.sh"   # OMZ will skip compinit because we ran it

# ---- 5) Prompt init (choose one: we keep p10k; Starship disabled) -

[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh

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
if [[ -r "$HOME/.bun/_bun" ]]; then
  source "$HOME/.bun/_bun"
fi

# fclones completions (guard)
command -v fclones >/dev/null 2>&1 && source <(fclones complete zsh)

# mise activation (guard)
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Conda (only if installed; noisy otherwise)
if [[ -x "/opt/anaconda3/bin/conda" ]]; then
  eval "$(/opt/anaconda3/bin/conda shell.zsh hook)" 2>/dev/null || true
fi

# ---- 9) Key bindings --------------------------------------------

# History substring search bindings
# ↑ Up arrow = search history backwards for lines starting with current input
bindkey '^[[A' history-substring-search-up
# ↓ Down arrow = search history forwards for lines starting with current input
bindkey '^[[B' history-substring-search-down

# Menu completion bindings
# ⏎ Enter = accept current menu selection and execute
bindkey -M menuselect '^M' .accept-line
# ⇄ Tab = trigger menu completion (show/navigate completion menu)
bindkey '^I' menu-complete
# ⇧⇄ Shift+Tab = cycle backwards through completions (from terminfo)
bindkey "$terminfo[kcbt]" reverse-menu-complete

# Undo/Redo bindings
# Ctrl+X then Ctrl+_ (Ctrl+Shift+minus); redo last undone action
bindkey "^X^_" redo
# Ctrl+U; delete from cursor to start of line (backward-kill-line)
bindkey "^U" backward-kill-line

# ---- 10) Aliases & helpers (restored + tidy) ---------------------
# Build/Run
alias build='nocorrect build'
alias run='nocorrect run'

# Quick inspectors
alias aliases="alias | sed 's/=.*//'"
alias paths='echo -e ${PATH//:/\\n}'

# Directory listings (eza)
alias l="eza -l -a -h --group-directories-first --classify=always --icons=always --no-permissions --no-user --time-style=long-iso --sort=modified --hyperlink"
alias lt="eza --tree --level=2 --long --icons"

# Folders & nav
alias ..="cd .."
alias ...="cd ../.."
alias lastdl='open kmtrigger://macro=Open%20most%20recently%20downloaded%20file'

# Editors & apps
alias cat='bat'
alias nano='micro'
alias code='bash "$HOME/.vscode-launcher.sh"'
alias fz='fzf --preview "bat --style=header --color=always --line-range :50 {}" --preview-window=right:60% | xargs open'
alias helium-personal='open -na "Helium" --args --profile-directory="Default"'
alias helium-work='open -na "Helium" --args --profile-directory="Profile 1"'

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



# SettingsSentry backup
alias settingssentry-backup='/Users/jason/dotfiles/settings/settings_sentry/settingssentry backup -backup="backups" -zip -log="logs"'
alias settingssentry-restore='/Users/jason/dotfiles/settings/settings_sentry/settingssentry restore -backup="backups" -log="logs"'

# Mackup backup
alias mackup-backup='~/dotfiles/mackup/mackup-backup.sh'
alias mackup-restore='~/dotfiles/mackup/mackup-restore.sh'

# Karabiner config rebuild
alias kbuild='nocorrect (cd ~/dotfiles/karabiner/karabiner.ts && npm run build)'

# Common mistakes
alias clear='\clear'

# One reload alias (login-style)
alias reload='\clear && source ~/.zshrc && echo "Reloaded .zshrc"'

# ---- Kitty shell integration (REPLACE lines 199-207) ----
# Enhanced version with more features while maintaining iTerm2 compatibility

if [[ "$TERM" == "xterm-kitty" ]]; then
    # SSH with proper terminfo propagation
    alias ssh="kitty +kitten ssh"

    # Image viewing in terminal
    alias icat="kitty +kitten icat"

    # File transfer over SSH
    alias kcp="kitty +kitten transfer"

    # Theme switching (requires allow_remote_control in kitty.conf)
    kitty-dark()  { kitty @ set-colors --all ~/.config/kitty/themes/dark.conf 2>/dev/null || echo "Enable allow_remote_control in kitty.conf" >&2; }
    kitty-light() { kitty @ set-colors --all ~/.config/kitty/themes/light.conf 2>/dev/null || echo "Enable allow_remote_control in kitty.conf" >&2; }

    # Broadcast input to all windows (like iTerm2's broadcast)
    kitty-broadcast() { kitty +kitten broadcast; }

    # New window/tab in current directory
    kitty-new() { kitty @ new-window --cwd="$PWD" "$@"; }
    kitty-tab() { kitty @ new-tab --cwd="$PWD" "$@"; }

    # Window title hooks (show directory and running command)
    autoload -Uz add-zsh-hook
    _kitty_title_precmd()  { print -Pn "\e]2;%~\a"; }
    _kitty_title_preexec() { print -Pn "\e]2;%~ ❯ ${1%%$'\n'*}\a"; }
    add-zsh-hook precmd _kitty_title_precmd
    add-zsh-hook preexec _kitty_title_preexec
fi
# Yazi smart-cd wrapper (with direct-dir fast path)
y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# ripgrep-all finder with preview (opens via macOS 'open')
# Usage: ff <search-term>
# Ensure no plugin alias (e.g., OMZ common-aliases) shadows this function
# unalias ff 2>/dev/null
ff() {
  [[ "$#" -gt 0 ]] || { echo "Usage: ff <search-term>"; return 1; }
  local file
  file="$(rga --max-count=1 --ignore-case --files-with-matches --no-messages "$*" \
        | fzf-tmux +m --preview="rga --ignore-case --pretty --context 10 '$*' {}")" \
        && echo "opening $file" && open "$file" || return 1
}

# fuzzy cd using locate + fzf
# Usage: cf <search-pattern>
cf() {
  local file
  file="$(locate -i "$@" | grep -v '~$' | fzf -0 -1)"
  [[ -n "$file" ]] || return
  if [[ -d "$file" ]]; then cd -- "$file"; else cd -- "${file:h}"; fi
}

# pick processes and kill
# Usage: fkill [signal] - defaults to SIGKILL (-9)
fkill() {
  local pid
  if [[ "$UID" != "0" ]]; then
    pid=$(ps -f -u "$UID" | sed 1d | fzf -m | awk '{print $2}')
  else
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  fi
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -"${1:-9}"
}

# Claude Smart Launcher (provides claude, claude-smart, c, cl aliases)
# See: ~/dotfiles/.claude/claude-secure/SETUP.md
[[ -r "$HOME/dotfiles/.claude/claude-secure/term-integration.sh" ]] && \
  source "$HOME/dotfiles/.claude/claude-secure/term-integration.sh"

# Cling helper function
# Usage: cling <file-or-folder> ...
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

# ---- 11) PATH consolidation ----------------------------------------
typeset -U path PATH
path=(
  "$HOME/Scripts/Metascripts/hsLauncher/scripts"
  "$HOME/.cache/lm-studio/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/dotfiles/bin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/go/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/System/Cryptexes/App/usr/bin"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
  $path
)
export PATH

# ---- 12) Final tool inits & niceties --------------------------------

# Docker completions (fpath only; compinit already run above)
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

# thefuck alias (guard for speed)
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"

# tv init (guard)
command -v tv >/dev/null 2>&1 && eval "$(tv init zsh)"

# fzf (guard; fallback if not loaded by fzf --zsh above)
[[ ! -v FZF_DEFAULT_OPTS && -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# >>> Added by Spyder >>>
alias uninstall-spyder=/Users/jason/Library/spyder-6/uninstall-spyder.sh
# <<< Added by Spyder <<<
