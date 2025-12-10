#!/bin/bash
# Claude Code API Key Helper for z.ai via 1Password
# This script is called by Claude Code (both CLI and VS Code extension)
# to fetch the API key dynamically

# Fetch the z.ai API key from 1Password
op read "op://Secrets/GLM_API/apikey2" 2>/dev/null
