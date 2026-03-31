#!/bin/bash
# status.sh -- Diagnostic script for Claude Permission Light.
# Reports the health of the installation: dependency presence, hook
# configuration, and blink process state.
#
# Usage:
#   ./bin/status.sh
#
# Exit code: 0 if all checks pass, non-zero = number of failures.

set -euo pipefail

# ---------------------------------------------------------------------------
# Source shared library
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

failures=0

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

echo "Claude Permission Light - Status"
echo "================================"

# ---------------------------------------------------------------------------
# Check 1: imagesnap installed (DIAG-01)
# ---------------------------------------------------------------------------

if command -v imagesnap >/dev/null 2>&1; then
  version=$(imagesnap -h 2>&1 | head -1 || echo "unknown")
  echo "[OK] imagesnap installed ($version)"
else
  echo "[FAIL] imagesnap not installed (run: brew install imagesnap)"
  failures=$((failures + 1))
fi

# ---------------------------------------------------------------------------
# Check 2: Hooks configured in settings.json (DIAG-02)
# ---------------------------------------------------------------------------

SETTINGS_FILE="${HOME}/.claude/settings.json"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "[FAIL] No settings.json found at $SETTINGS_FILE"
  failures=$((failures + 1))
elif ! command -v jq >/dev/null 2>&1; then
  echo "[WARN] jq not installed -- cannot check hooks (run: brew install jq)"
else
  # Check Notification hook -- uses contains() match like uninstall.sh
  if jq -e '
    .hooks.Notification // [] |
    map(select(.hooks // [] | any(.command | tostring | contains("permission-signal.sh")))) |
    length > 0
  ' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo "[OK] Notification hook configured"
  else
    echo "[FAIL] Notification hook not found (run: ./install.sh)"
    failures=$((failures + 1))
  fi

  # Check Stop hook -- uses contains() match like uninstall.sh
  if jq -e '
    .hooks.Stop // [] |
    map(select(.hooks // [] | any(.command | tostring | contains("permission-cleanup.sh")))) |
    length > 0
  ' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo "[OK] Stop hook configured"
  else
    echo "[FAIL] Stop hook not found (run: ./install.sh)"
    failures=$((failures + 1))
  fi
fi

# ---------------------------------------------------------------------------
# Check 3: Blink process running (DIAG-03)
# ---------------------------------------------------------------------------

if is_running; then
  pid=$(cat "$PID_FILE" 2>/dev/null)
  echo "[OK] Blink process running (pid=$pid)"
else
  echo "[--] Blink process not running (normal when no permission prompt is active)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
if [[ "$failures" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "$failures issue(s) found."
fi

exit "$failures"
