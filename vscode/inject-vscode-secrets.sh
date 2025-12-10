#!/bin/bash
# VSCode secrets injector
# Run this script to write 1Password secrets to VSCode settings
# Usage: ./inject-vscode-secrets.sh

set -e

VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code - Insiders/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

echo "[vscode-inject] Loading secrets from 1Password..."

# Load secrets
Z_KEY=$(op read "op://Secrets/GLM_API/apikey2" 2>/dev/null) || {
  echo "[vscode-inject] ERROR: Could not load Z_AI_API_KEY" >&2
  exit 1
}

CTX_KEY=$(op read "op://Secrets/Context7_API/api_key" 2>/dev/null) || true
GH_TOKEN=$(op read "op://Secrets/GitHub Personal Access Token/token" 2>/dev/null) || true
OAI_KEY=$(op read "op://Secrets/oAI_API/api_key2" 2>/dev/null) || true

# Create settings directory if needed
mkdir -p "$VSCODE_SETTINGS_DIR"

# Backup existing settings
if [[ -f "$VSCODE_SETTINGS_FILE" ]]; then
  cp "$VSCODE_SETTINGS_FILE" "$VSCODE_SETTINGS_FILE.backup-$(date +%s)"
  echo "[vscode-inject] Backed up existing settings"
fi

# Create/update settings with secrets using jq
python3 << PYTHON
import json
import os
from pathlib import Path

settings_file = Path("$VSCODE_SETTINGS_FILE")
settings = {}

# Load existing settings if file exists
if settings_file.exists():
    with open(settings_file, 'r') as f:
        try:
            settings = json.load(f)
        except:
            settings = {}

# Update with Claude extension z.ai settings
settings.update({
    "claude.apiKey": "$Z_KEY",
    "claude.apiBaseUrl": "https://api.z.ai/api/anthropic",
    "claude.requestTimeout": 30000,
    "anthropic.apiKey": "$Z_KEY",
    "anthropic.baseUrl": "https://api.z.ai/api/anthropic",
})

# Add optional keys if available
if "$CTX_KEY":
    settings["context7.apiKey"] = "$CTX_KEY"
if "$GH_TOKEN":
    settings["github.token"] = "$GH_TOKEN"
if "$OAI_KEY":
    settings["openai.apiKey"] = "$OAI_KEY"

# Write back
settings_file.parent.mkdir(parents=True, exist_ok=True)
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("[vscode-inject] Settings updated successfully")
PYTHON

echo "[vscode-inject] Done! Restart VSCode Insiders for changes to take effect."
