Check or manage macOS camera permission for Claude Permission Light.

Arguments: $ARGUMENTS (optional: "check", "grant", "revoke")

## If no argument or "check":
Check current camera permission status:
1. Run `imagesnap -w 0 /tmp/claude-cam-perm-test.jpg 2>&1` and capture output
2. If the capture succeeds (file created): camera permission is granted. Report "Camera permission: GRANTED" and clean up with `rm -f /tmp/claude-cam-perm-test.jpg`
3. If the capture fails or output contains "error" or "denied": camera permission is missing. Report "Camera permission: NOT GRANTED" and show fix instructions
4. Also check which terminal app needs permission: report the value of `$TERM_PROGRAM` (e.g., "Apple_Terminal", "iTerm2", "WarpTerminal")
5. Tell user: "Camera access must be granted to: $TERM_PROGRAM in System Settings > Privacy & Security > Camera"

## If "grant":
Trigger the macOS camera permission dialog:
1. Run `imagesnap -w 0 /tmp/claude-cam-perm-grant.jpg 2>&1`
2. Tell user: "If you see a macOS permission dialog, click Allow. If no dialog appeared, permission was already granted."
3. Clean up: `rm -f /tmp/claude-cam-perm-grant.jpg`
4. Verify by running the "check" flow above

## If "revoke":
Guide the user to revoke camera permission manually:
1. Tell user: "macOS does not allow revoking camera permission programmatically. To revoke:"
2. Show steps:
   - Open **System Settings**
   - Go to **Privacy & Security > Camera**
   - Find your terminal app (Terminal, iTerm2, Warp, etc.)
   - Toggle it **OFF**
3. Tell user: "After revoking, the LED will no longer blink. Run `/claude-permission-light:permission grant` to re-enable."
