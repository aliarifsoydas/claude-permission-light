#!/bin/bash
# common.sh -- Shared constants and utility functions for Claude Permission Light.
# This file is sourced by other scripts, not executed directly.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Directory for state files (PID, lock)
STATE_DIR="${HOME}/.claude-permission-light"

# PID file location
PID_FILE="${STATE_DIR}/blink.pid"

# mkdir-based atomic lock directory
LOCK_DIR="${STATE_DIR}/blink.lock"

# Total blink cycle time in seconds (on + off). Configurable via env var.
BLINK_INTERVAL="${CAM_BLINK_INTERVAL:-1}"

# Max seconds before self-termination
BLINK_TIMEOUT=600

# imagesnap output file (discarded -- we only want the LED side-effect)
SNAP_OUTPUT="/tmp/claude-cam-snap.jpg"

# Camera device name. Set CAM_DEVICE to override auto-detection.
# Auto-detect: prefer FaceTime camera over virtual cameras (OBS, etc.)
if [[ -z "${CAM_DEVICE:-}" ]]; then
  CAM_DEVICE=$(imagesnap -l 2>/dev/null | grep -i "FaceTime" | head -1 | sed 's/^=> //' || true)
  if [[ -z "$CAM_DEVICE" ]]; then
    CAM_DEVICE=""  # empty = imagesnap system default
  fi
fi

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# log -- Print message to stderr with [cam] prefix.
# Only prints if CAM_DEBUG=1 is set.
log() {
  [[ "${CAM_DEBUG:-0}" == "1" ]] && printf '[cam] %s\n' "$*" >&2
  return 0
}

# log_error -- Always print to stderr with [cam] ERROR: prefix.
# Not gated by CAM_DEBUG -- errors are always visible.
log_error() {
  printf '[cam] ERROR: %s\n' "$*" >&2
}

# is_running -- Check if PID from PID file is alive AND is a camera-blink process.
# Takes no arguments, reads PID_FILE.
# Returns 0 if running, 1 if not.
is_running() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid=$(cat "$PID_FILE" 2>/dev/null) || return 1
  [[ -n "$pid" ]] || return 1
  local comm
  comm=$(ps -p "$pid" -o comm= 2>/dev/null) || return 1
  [[ "$comm" == *"camera-blink"* ]] || return 1
  return 0
}

# cleanup_stale_pid -- If PID file exists but process is dead, remove PID file
# and lock dir. Call this before starting a new blink.
cleanup_stale_pid() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null) || { rm -f "$PID_FILE"; return 0; }
    if ! kill -0 "$pid" 2>/dev/null; then
      log "Cleaning up stale PID file (pid=$pid)"
      rm -f "$PID_FILE"
      rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
  fi
  return 0
}

# ensure_state_dir -- Create STATE_DIR if it does not exist.
ensure_state_dir() {
  mkdir -p "$STATE_DIR"
}

# End of common.sh
