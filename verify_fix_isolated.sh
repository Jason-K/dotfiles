#!/bin/bash
set -euo pipefail
brewfile="$HOME/dotfiles/brew/Brewfile.test"

echo "Testing with known satisfied dependency..."
if brew bundle check --file="$brewfile" &>/dev/null; then
  echo "🍺 Homebrew Bundle: Dependencies satisfied."
else
  echo "🍺 Homebrew Bundle: Installing/Updating packages..."
  brew bundle install --quiet --file="$brewfile"
fi

echo "Testing with missing dependency..."
# Use a fake package that brew check will definitely fail on
echo 'brew "package-that-does-not-exist-at-all"' >> "$brewfile"

if brew bundle check --file="$brewfile" &>/dev/null; then
  echo "🍺 Homebrew Bundle: Dependencies satisfied."
else
  echo "🍺 Homebrew Bundle: Installing/Updating packages..."
  # We expect this to fail, so suppress error
  brew bundle install --quiet --file="$brewfile" || echo "Install failed as expected."
fi
