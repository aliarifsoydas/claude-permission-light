Set up Claude Permission Light dependencies and verify the installation.

Arguments: $ARGUMENTS (optional: "check", "install", "fix")

## If no argument or "check":
Run diagnostics only — do not install anything:
1. `command -v brew` — Homebrew installed?
2. `command -v imagesnap` — imagesnap installed?
3. `command -v jq` — jq installed?
4. `imagesnap -l 2>/dev/null | grep -i FaceTime` — FaceTime camera available?
5. Check camera TCC permission: `imagesnap -w 0 /tmp/claude-cam-check.jpg 2>&1` then `rm -f /tmp/claude-cam-check.jpg`

Report results as a checklist.

## If "install":
Install missing dependencies:
1. If imagesnap missing: `brew install imagesnap`
2. If jq missing: `brew install jq`
3. Trigger camera permission: `imagesnap -w 0 /tmp/claude-cam-setup.jpg 2>&1; rm -f /tmp/claude-cam-setup.jpg`
4. Run the "check" flow to verify

## If "fix":
Diagnose and fix common issues:
1. If imagesnap captures from wrong camera (OBS Virtual Camera), suggest: `export CAM_DEVICE="FaceTime HD Camera"`
2. If camera permission denied, guide user to System Settings > Privacy & Security > Camera
3. If blink process is stuck, run: `${CLAUDE_PLUGIN_ROOT}/bin/camera-blink.sh stop`
4. Clean up stale PID files: `rm -f ~/.claude-permission-light/blink.pid`
