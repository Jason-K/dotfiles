#!/usr/bin/env zsh
# Update Brewfile with currently installed packages

set -e

DOTFILES_DIR="${HOME}/dotfiles"
BREW_DIR="${DOTFILES_DIR}/brew"
BACKUP_DIR="${BREW_DIR}/backups"
BREWFILE="${BREW_DIR}/brewfile"
BACKUP_FILE="${BACKUP_DIR}/Brewfile.$(date +%Y%m%d%H%M%S).backup"

echo "confirming directory structure..."

if [[ ! -d "${BREW_DIR}" ]]; then
  mkdir -p "${BREW_DIR}"
  echo "Created directory: ${BREW_DIR}"
  echo ""
fi

if [[ ! -d "${BACKUP_DIR}" ]]; then
  mkdir -p "${BACKUP_DIR}"
  echo "Created directory: ${BACKUP_DIR}"
  echo ""
fi

echo "Backing up current Brewfile..."
if [[ -f "${BREWFILE}" ]]; then
  cp "${BREWFILE}" "${BACKUP_FILE}"
  echo "Backup created at ${BACKUP_FILE}"
  echo ""
fi

echo "Generating new Brewfile from installed packages..."
cd "${BREW_DIR}"
brew bundle dump --force --describe

echo "✓ Brewfile updated successfully!"
echo ""
echo "Review changes with: git diff ${BREWFILE}"
echo "Restore backup with: mv ${BACKUP_FILE} ${BREWFILE}"
