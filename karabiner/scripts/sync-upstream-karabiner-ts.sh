#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

REMOTE_NAME="upstream-karabiner-ts"
REPO_URL="https://github.com/evan-liu/karabiner.ts"
UPSTREAM_DIR="karabiner.ts-upstream"
SUBPROJECT_DIR="karabiner.ts"

echo "==> Ensuring upstream remote..."
if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  git remote add "$REMOTE_NAME" "$REPO_URL"
fi

echo "==> Fetching upstream..."
git fetch "$REMOTE_NAME" --tags

echo "==> Refreshing $UPSTREAM_DIR from $REMOTE_NAME/main ..."
mkdir -p "$UPSTREAM_DIR"
# Clean target directory but preserve .git if any (it shouldn't be a repo)
rm -rf "$UPSTREAM_DIR"/*
# Checkout tree into work-tree without touching index
GIT_WORK_TREE="$UPSTREAM_DIR" git checkout "$REMOTE_NAME/main" -- .

echo "==> Syncing upstream workflows and docs into subproject safe paths..."
mkdir -p "$SUBPROJECT_DIR/.github/upstream-workflows"
cp -a "$UPSTREAM_DIR/.github/workflows/." "$SUBPROJECT_DIR/.github/upstream-workflows/" 2>/dev/null || true
mkdir -p "$SUBPROJECT_DIR/docs/upstream"
rsync -a --delete "$UPSTREAM_DIR/docs/" "$SUBPROJECT_DIR/docs/upstream/" 2>/dev/null || true

if [ -x "$SUBPROJECT_DIR/scripts/generate-conflict-report.sh" ]; then
  echo "==> Regenerating conflict report..."
  (cd "$SUBPROJECT_DIR" && ./scripts/generate-conflict-report.sh)
else
  echo "==> Skipping conflict report (script not found)."
fi

echo "==> Done. Review changes and commit as needed."
