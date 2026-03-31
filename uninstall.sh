#!/bin/bash
# uninstall.sh -- Remove Claude Permission Light hooks and clean up.
# Removes only its own hook entries from settings.json, stops any running
# blink process, and cleans up state files. Idempotent: safe to run when
# already uninstalled.
#
# Usage: ./uninstall.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared library for STATE_DIR, PID_FILE, LOCK_DIR, SNAP_OUTPUT
source "${SCRIPT_DIR}/lib/common.sh"

SETTINGS_FILE="${HOME}/.claude/settings.json"

# ---------------------------------------------------------------------------
# Step 1: Stop any running blink process
# ---------------------------------------------------------------------------

echo "Stopping blink process..."
"${SCRIPT_DIR}/bin/camera-blink.sh" stop 2>/dev/null || true

# Clean up the snap output file
rm -f "$SNAP_OUTPUT"

# If state directory exists and is now empty, remove it
if [[ -d "$STATE_DIR" ]]; then
  rmdir "$STATE_DIR" 2>/dev/null || true
fi

echo "Stopped blink process and cleaned up state files"

# ---------------------------------------------------------------------------
# Step 2: Remove hooks from settings.json
# ---------------------------------------------------------------------------

# Check if settings.json exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "No settings.json found -- nothing to remove"
else
  # Check if jq is available
  if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq not found -- cannot modify settings.json. Remove hooks manually." >&2
  else
    echo "Removing hooks from settings.json..."

    # Remove Notification hook entries that contain permission-signal.sh
    jq '
      if .hooks and .hooks.Notification then
        .hooks.Notification |= map(select(.hooks | all(.command | contains("permission-signal.sh") | not)))
      else . end
    ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    # Remove Stop hook entries that contain permission-cleanup.sh
    jq '
      if .hooks and .hooks.Stop then
        .hooks.Stop |= map(select(.hooks | all(.command | contains("permission-cleanup.sh") | not)))
      else . end
    ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    # Clean up empty arrays and empty hooks object
    jq '
      if .hooks then
        (if .hooks.Notification and (.hooks.Notification | length) == 0 then del(.hooks.Notification) else . end) |
        (if .hooks.Stop and (.hooks.Stop | length) == 0 then del(.hooks.Stop) else . end) |
        (if .hooks and (.hooks | length) == 0 then del(.hooks) else . end)
      else . end
    ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    echo "Hooks removed from ~/.claude/settings.json"
  fi
fi

# ---------------------------------------------------------------------------
# Success
# ---------------------------------------------------------------------------

echo ""
echo "Claude Permission Light uninstalled successfully."
echo "To reinstall, run: ./install.sh"
