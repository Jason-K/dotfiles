# ~/bin/inventory_mac.sh  (run once)
set -euo pipefail
OUT="${HOME}/dotfiles/system-inventory"; mkdir -p "$OUT"/{apps,configs,dev,system}
timestamp() { date +"%Y-%m-%d_%H-%M-%S"; }

# 1) Homebrew
brew --version >/dev/null 2>&1 && {
  brew update || true
  brew bundle dump --all --file="$OUT/Brewfile"
  brew leaves        > "$OUT/apps/brew_leaves.txt"
  brew list --cask   > "$OUT/apps/brew_casks.txt"
  brew list          > "$OUT/apps/brew_formulae.txt"
}

# 2) App Store
command -v mas >/dev/null 2>&1 && mas list > "$OUT/apps/mas_apps.txt" || true

# 3) Applications (dragged installs)
ls -1 /Applications                > "$OUT/apps/Applications_root.txt" 2>/dev/null || true
ls -1 "$HOME/Applications"         > "$OUT/apps/Applications_user.txt" 2>/dev/null || true

# 4) Login items & launch items
osascript -e 'tell application "System Events" to get name of every login item' \
  > "$OUT/system/login_items.txt" || true
launchctl list                     > "$OUT/system/launchctl_list.txt" || true
ls -1 ~/Library/LaunchAgents       > "$OUT/system/LaunchAgents_user.txt" 2>/dev/null || true
ls -1 /Library/LaunchAgents        > "$OUT/system/LaunchAgents_global.txt" 2>/dev/null || true
ls -1 /Library/LaunchDaemons       > "$OUT/system/LaunchDaemons_global.txt" 2>/dev/null || true
crontab -l                         > "$OUT/system/crontab.txt" 2>/dev/null || true

# 5) Shell & Git
echo "$SHELL"                    > "$OUT/system/shell.txt"
zsh --version                    > "$OUT/system/zsh_version.txt" 2>/dev/null || true
bash --version                   > "$OUT/system/bash_version.txt" 2>/dev/null || true
git --version                    > "$OUT/dev/git_version.txt"     2>/dev/null || true
git config --global -l           > "$OUT/dev/git_config_global.txt" 2>/dev/null || true

# 6) SSH / GPG (just listing—do NOT copy secrets here)
ls -l ~/.ssh                      > "$OUT/dev/ssh_keys_listing.txt" 2>/dev/null || true
gpg --version                     > "$OUT/dev/gpg_version.txt" 2>/dev/null || true
gpg --list-keys                   > "$OUT/dev/gpg_public_keys.txt" 2>/dev/null || true

# 7) Dev toolchains
# Python
{ pyenv versions || true; asdf list python || true; } > "$OUT/dev/python_versions.txt" 2>/dev/null
python3 --version                    > "$OUT/dev/python_default.txt" 2>/dev/null || true
pipx list                            > "$OUT/dev/pipx_list.txt" 2>/dev/null || true
pip3 list --format=freeze            > "$OUT/dev/pip3_freeze.txt" 2>/dev/null || true

# Node
{ nvm ls || true; fnm list || true; volta list || true; asdf list nodejs || true; } \
  > "$OUT/dev/node_versions.txt" 2>/dev/null
npm -g list --depth=0                > "$OUT/dev/npm_global.txt" 2>/dev/null || true
pnpm -g list --depth=0               > "$OUT/dev/pnpm_global.txt" 2>/dev/null || true
corepack --version                   > "$OUT/dev/corepack.txt" 2>/dev/null || true

# Ruby / Go
{ rbenv versions || asdf list ruby || true; } > "$OUT/dev/ruby_versions.txt" 2>/dev/null
go version                            > "$OUT/dev/go_version.txt" 2>/dev/null || true
ls -1 ~/go/bin                        > "$OUT/dev/go_bin_listing.txt" 2>/dev/null || true

# 8) Editors & extensions
command -v code >/dev/null 2>&1 && code --list-extensions > "$OUT/dev/vscode_extensions.txt" || true
command -v idea >/dev/null 2>&1 && echo "[JetBrains installed]" > "$OUT/dev/jetbrains.txt" || true

# 9) Key app configs (non-secret paths only)
for p in \
  "$HOME/.hammerspoon" \
  "$HOME/.config/karabiner" \
  "$HOME/Library/Application Support/Keyboard Maestro" \
  "$HOME/Library/Application Support/Noodlesoft/Hazel" \
  "$HOME/Library/Preferences/org.hammerspoon.Hammerspoon.plist" \
  "$HOME/Library/Preferences/org.pqrs.Karabiner-Elements.plist"
do
  [ -e "$p" ] && echo "$p" >> "$OUT/configs/paths_captured.txt"
done

# 10) macOS Defaults snapshot (safe read-only)
plutil -convert xml1 ~/Library/Preferences/com.apple.finder.plist -o "$OUT/configs/finder.plist" 2>/dev/null || true
defaults read -g    > "$OUT/configs/defaults_global_$(timestamp).txt"  2>/dev/null || true
defaults read com.apple.finder > "$OUT/configs/defaults_finder.txt"    2>/dev/null || true
defaults read com.apple.dock   > "$OUT/configs/defaults_dock.txt"      2>/dev/null || true

echo "Inventory complete in $OUT"
