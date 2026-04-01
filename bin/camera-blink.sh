#!/bin/bash
# camera-blink.sh -- Core blink engine for Claude Permission Light.
# Activates the MacBook camera LED in a visible on/off pattern.
#
# Usage:
#   camera-blink.sh start   Start blinking (default if no argument)
#   camera-blink.sh stop    Stop blinking

set -euo pipefail

# ---------------------------------------------------------------------------
# Source shared library
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# ---------------------------------------------------------------------------
# Cleanup function (used by trap in the background subshell)
# ---------------------------------------------------------------------------

cleanup() {
  rm -f "$PID_FILE"
  rmdir "$LOCK_DIR" 2>/dev/null || true
  log "Blink cleanup complete"
}

# ---------------------------------------------------------------------------
# stop_blink -- Stop a running blink process
# ---------------------------------------------------------------------------

stop_blink() {
  if [[ ! -f "$PID_FILE" ]]; then
    log "No blink process found"
    return 0
  fi

  local pid
  pid=$(cat "$PID_FILE" 2>/dev/null) || {
    rm -f "$PID_FILE"
    return 0
  }

  # Check if process is still alive
  if ! kill -0 "$pid" 2>/dev/null; then
    log "Blink process already dead, cleaning up"
    rm -f "$PID_FILE"
    rmdir "$LOCK_DIR" 2>/dev/null || true
    rm -f "$SNAP_OUTPUT"
    return 0
  fi

  # Send SIGTERM first (graceful shutdown)
  kill "$pid" 2>/dev/null || true
  log "Sent SIGTERM to blink process (pid=$pid)"

  # Wait up to 2 seconds for process to die
  local i
  for i in 1 2 3 4; do
    sleep 0.5
    kill -0 "$pid" 2>/dev/null || break
  done

  # If still alive after 2 seconds, send SIGKILL
  if kill -0 "$pid" 2>/dev/null; then
    log "Process still alive after SIGTERM, sending SIGKILL"
    kill -9 "$pid" 2>/dev/null || true
  fi

  # Clean up files
  rm -f "$PID_FILE"
  rmdir "$LOCK_DIR" 2>/dev/null || true
  rm -f "$SNAP_OUTPUT"

  log "Blink stopped"
  return 0
}

# ---------------------------------------------------------------------------
# do_start -- Start the blink loop
# ---------------------------------------------------------------------------

do_start() {
  # Check imagesnap is installed
  if ! command -v imagesnap >/dev/null 2>&1; then
    log_error "imagesnap not found. Install with: brew install imagesnap"
    exit 0
  fi

  # Create state directory
  ensure_state_dir

  # Clean up any stale PID files
  cleanup_stale_pid

  # Acquire atomic lock
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    # Lock exists -- check if blink is truly running
    if is_running; then
      log "Blink already running"
      exit 0
    else
      # Stale lock -- clean up and retry
      cleanup_stale_pid
      rmdir "$LOCK_DIR" 2>/dev/null || true
      if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        log_error "Failed to acquire blink lock"
        exit 0
      fi
    fi
  fi

  # If a previous blink is running, stop it first (single instance)
  if [[ -f "$PID_FILE" ]]; then
    stop_blink
  fi

  # Start the blink loop as a background subshell
  (
    trap 'cleanup' EXIT

    local_start_time=$(date +%s)

    while true; do
      # Self-termination check (60-second timeout)
      current_time=$(date +%s)
      elapsed=$((current_time - local_start_time))
      if [[ $elapsed -ge $BLINK_TIMEOUT ]]; then
        log "Blink timeout reached (${BLINK_TIMEOUT}s), self-terminating"
        break
      fi

      # Camera ON phase (LED activates during capture)
      half_interval=$(echo "$BLINK_INTERVAL / 2" | bc -l 2>/dev/null || echo "0.5")
      # Build imagesnap args -- use -d flag only if CAM_DEVICE is set
      snap_args=(-w 0)
      if [[ -n "${CAM_DEVICE:-}" ]]; then
        snap_args+=(-d "$CAM_DEVICE")
      fi
      imagesnap "${snap_args[@]}" "$SNAP_OUTPUT" >/dev/null 2>&1 || {
        log_error "imagesnap failed to capture -- stopping blink loop"
        break
      }

      # Camera OFF phase (LED off during sleep)
      sleep "$half_interval"
    done
  ) &

  # Capture background PID and write to PID file
  echo $! > "$PID_FILE"

  # Release the lock
  rmdir "$LOCK_DIR" 2>/dev/null || true

  log "Blink started (pid=$!, interval=${BLINK_INTERVAL}s, timeout=${BLINK_TIMEOUT}s)"

  exit 0
}

# ---------------------------------------------------------------------------
# do_stop -- Stop the blink loop
# ---------------------------------------------------------------------------

do_stop() {
  stop_blink
  exit 0
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------

case "${1:-start}" in
  start) do_start ;;
  stop)  do_stop ;;
  *)     echo "Usage: camera-blink.sh [start|stop]" >&2; exit 1 ;;
esac
