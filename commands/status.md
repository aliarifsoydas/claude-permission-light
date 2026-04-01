Check if Claude Permission Light is properly installed and working.

Run the following checks and report results:

1. **imagesnap**: Run `command -v imagesnap` — report installed or missing
2. **Camera access**: Run `imagesnap -l 2>/dev/null` — check if FaceTime camera is listed
3. **Hook scripts**: Check if `${CLAUDE_PLUGIN_ROOT}/bin/permission-signal.sh` and `${CLAUDE_PLUGIN_ROOT}/bin/permission-cleanup.sh` exist and are executable
4. **Blink process**: Check if `~/.claude-permission-light/blink.pid` exists and process is alive

Report each as OK or FAIL with fix instructions.
