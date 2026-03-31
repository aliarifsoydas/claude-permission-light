#!/bin/bash
# permission-signal.sh -- Claude Code Notification hook entry point.
# Called when a permission_prompt event fires.
# Starts the camera LED blink loop to alert the user.

set -euo pipefail

# Drain stdin -- Claude Code passes JSON payload via stdin.
# We do not need to parse it (per HOOK-03, CONTEXT.md decision).
# Failing to drain stdin can cause Claude Code to hang waiting for the pipe.
cat > /dev/null 2>&1 || true

# Resolve script directory for sibling script references
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Start the blink loop (camera-blink.sh handles all process management)
"${SCRIPT_DIR}/camera-blink.sh" start

# Always exit 0 -- never block Claude Code (per HOOK-04, ERR-01)
exit 0
