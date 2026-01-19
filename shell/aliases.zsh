# ==================================================================
# Shell Aliases — Organized by category
# ==================================================================

# ---- Build/Run ----
alias build='nocorrect build'
alias run='nocorrect run'

# ---- Quick Inspectors ----
alias aliases="alias | sed 's/=.*//'"
alias paths='echo -e ${PATH//:/\\n}'

# ---- Directory Listings (eza) ----
alias l="eza -l -a -h --group-directories-first --classify=always --icons=always --no-permissions --no-user --time-style=long-iso --sort=modified --hyperlink"
alias lt="eza --tree --level=2 --long --icons"
alias ltr="eza --tree --level=3 --long --icons"

# ---- Navigation ----
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias lastdl='open kmtrigger://macro=Open%20most%20recently%20downloaded%20file'

# ---- Editors & Tools ----
alias cat='bat'
alias nano='micro'
alias code='bash "$HOME/dotfiles/vscode/.vscode-launcher.sh"'
alias fz='fzf --preview "bat --style=header --color=always --line-range :50 {}" --preview-window=right:60% | xargs open'

# ---- Helium Browser Profiles ----
alias helium-personal='open -na "Helium" --args --profile-directory="Default"'
alias helium-work='open -na "Helium" --args --profile-directory="Profile 1"'

# ---- Network ----
alias ipp="dig +short myip.opendns.com @resolver1.opendns.com"
alias ipl="ip route get 1.1.1.1 2>/dev/null | awk 'NR==1{print \$7}'"
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'

# ---- macOS Maintenance ----
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes ~/.Trash; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# ---- macOS Developer Tools (absolute paths) ----
alias codesign=/usr/bin/codesign
alias stapler='/usr/bin/xcrun stapler'
alias notarytool='/usr/bin/xcrun notarytool'

# ---- Backup Tools ----
alias backup='~/dotfiles/scripts/backup.sh --essential'
alias restore='~/dotfiles/scripts/restore.sh'

# ---- Project-Specific ----
alias kbuild='nocorrect (cd ~/dotfiles/karabiner/karabiner.ts && npm run build)'

# ---- Shell Helpers ----
alias clear='\clear'
alias reload='\clear && source ~/.zshrc && echo "✅ Reloaded .zshrc"'

# ---- Spyder (auto-added by installer) ----
alias uninstall-spyder=/Users/jason/Library/spyder-6/uninstall-spyder.sh
