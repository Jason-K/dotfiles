#!/bin/zsh
set -euo pipefail

# Resolve script directory so the script is relocatable
SCRIPT_DIR="$(cd -- "$(dirname -- "${0}")" && pwd)"

HUNTER="${SCRIPT_DIR}/detect.jxa"
KILLER="${SCRIPT_DIR}/unfreeze-kill"

# Capture original first arg for foreground detection
FIRST_ARG="${1:-}"

# Default to fast mode and pid-only unless overridden
FAST=1
PID_ONLY=1
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--no-fast" ]]; then
    FAST=0
  elif [[ "$arg" == "--full" ]]; then
    PID_ONLY=0
  else
    ARGS+=("$arg")
  fi
done

# Build detector args
DETECTOR_ARGS=()
[[ "$PID_ONLY" -eq 1 ]] && DETECTOR_ARGS+=("--pid-only")

if [[ "$FIRST_ARG" == "--foreground" ]]; then
  shift
  if [[ "$FAST" -eq 1 ]]; then
    osascript -l JavaScript "$HUNTER" --foreground "${DETECTOR_ARGS[@]}" | "$KILLER" --fast "${ARGS[@]:1}"
  else
    osascript -l JavaScript "$HUNTER" --foreground "${DETECTOR_ARGS[@]}" | "$KILLER" "${ARGS[@]:1}"
  fi
  echo 'Foreground kill executed'
else
  if [[ "$FAST" -eq 1 ]]; then
    osascript -l JavaScript "$HUNTER" "${DETECTOR_ARGS[@]}" | "$KILLER" --fast "${ARGS[@]}"
  else
    osascript -l JavaScript "$HUNTER" "${DETECTOR_ARGS[@]}" | "$KILLER" "${ARGS[@]}"
  fi
  echo 'Unresponsive processes killed'
fi
