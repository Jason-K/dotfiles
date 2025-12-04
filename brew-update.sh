#!/usr/bin/env zsh
# Update Brewfile with currently installed packages

set -e

DOTFILES_DIR="${HOME}/dotfiles"
BREWFILE="${DOTFILES_DIR}/Brewfile"

echo "Backing up current Brewfile..."
if [[ -f "${BREWFILE}" ]]; then
  cp "${BREWFILE}" "${BREWFILE}.backup"
  echo "Backup created at ${BREWFILE}.backup"
fi

echo "Generating new Brewfile from installed packages..."
cd "${DOTFILES_DIR}"
brew bundle dump --force --describe

echo "✓ Brewfile updated successfully!"
echo ""
echo "Review changes with: git diff ${BREWFILE}"
echo "Restore backup with: mv ${BREWFILE}.backup ${BREWFILE}"
