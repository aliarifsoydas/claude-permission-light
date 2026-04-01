#!/bin/bash
# install.sh -- One-command setup for Claude Permission Light.
# Installs imagesnap, injects Claude Code hooks into settings.json,
# and triggers the macOS camera TCC permission prompt.
#
# Usage: ./install.sh
# Safe to run multiple times (idempotent).

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Resolve the absolute path of this repository, regardless of where the
# user runs the script from (e.g., ./install.sh, bash install.sh, etc.).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

SETTINGS_DIR="${HOME}/.claude"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

# Hook script paths (absolute -- resolved at install time)
SIGNAL_SCRIPT="${REPO_DIR}/bin/permission-signal.sh"
CLEANUP_SCRIPT="${REPO_DIR}/bin/permission-cleanup.sh"

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

# Homebrew -- required, never auto-installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required but not installed." >&2
  echo "Install from https://brew.sh" >&2
  exit 1
fi

# jq -- install via brew if missing (needed for JSON merge)
if ! command -v jq >/dev/null 2>&1; then
  echo "Installing jq..."
  brew install jq
fi

# imagesnap -- install via brew if missing
if ! command -v imagesnap >/dev/null 2>&1; then
  echo "Installing imagesnap..."
  brew install imagesnap
else
  echo "imagesnap already installed"
fi

# ---------------------------------------------------------------------------
# Hook injection into settings.json
# ---------------------------------------------------------------------------

# Ensure the .claude directory exists
mkdir -p "$SETTINGS_DIR"

# Create settings.json as empty object if it does not exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Define hook JSON entries.
# Using heredocs to build multi-line JSON strings safely.
NOTIFICATION_HOOK=$(cat <<EOF
{
  "matcher": "permission_prompt",
  "hooks": [
    {
      "type": "command",
      "command": "${SIGNAL_SCRIPT}"
    }
  ]
}
EOF
)

STOP_HOOK=$(cat <<EOF
{
  "hooks": [
    {
      "type": "command",
      "command": "${CLEANUP_SCRIPT}"
    }
  ]
}
EOF
)

# --- Notification hook ---
# Check if our Notification hook already exists (idempotency)
if jq -e '.hooks.Notification // [] | map(select(.hooks[].command == "'"${SIGNAL_SCRIPT}"'")) | length > 0' "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "Notification hook already configured"
else
  echo "Adding Notification hook..."
  jq --argjson hook "$NOTIFICATION_HOOK" \
    '.hooks //= {} | .hooks.Notification //= [] | .hooks.Notification += [$hook]' \
    "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
fi

# --- Stop hook ---
# Check if our Stop hook already exists (idempotency)
if jq -e '.hooks.Stop // [] | map(select(.hooks[].command == "'"${CLEANUP_SCRIPT}"'")) | length > 0' "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "Stop hook already configured"
else
  echo "Adding Stop hook..."
  jq --argjson hook "$STOP_HOOK" \
    '.hooks //= {} | .hooks.Stop //= [] | .hooks.Stop += [$hook]' \
    "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
fi

# ---------------------------------------------------------------------------
# Camera TCC permission prompt
# ---------------------------------------------------------------------------

echo "Testing camera access (you may see a macOS permission dialog)..."
imagesnap -w 0 /dev/null >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# Success
# ---------------------------------------------------------------------------

echo ""
echo "Claude Permission Light installed successfully!"
echo "Hooks added to ~/.claude/settings.json"
echo "Camera LED will blink when Claude Code requests permission."
