#!/bin/bash
# permission-cleanup.sh -- Claude Code Stop hook entry point.
# Called when Claude Code stops to clean up the blink loop.
# Stops the camera LED blink after a permission prompt is resolved.

set -euo pipefail

# Drain stdin -- Claude Code passes JSON payload via stdin.
# We do not need to parse it (per HOOK-03, CONTEXT.md decision).
cat > /dev/null 2>&1 || true

# Resolve script directory for sibling script references
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Stop the blink loop (camera-blink.sh handles graceful shutdown + cleanup)
# Wrap in || true so kill failures do not crash this script (per ERR-03)
"${SCRIPT_DIR}/camera-blink.sh" stop || true

# Always exit 0 -- never block Claude Code (per HOOK-04)
exit 0
