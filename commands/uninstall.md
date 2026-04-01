Completely remove Claude Permission Light from this machine.

Run these steps:

1. Stop any running blink process: `${CLAUDE_PLUGIN_ROOT}/bin/camera-blink.sh stop 2>/dev/null || true`
2. Clean up state files: `rm -f ~/.claude-permission-light/blink.pid && rmdir ~/.claude-permission-light 2>/dev/null || true`
3. Clean up temp files: `rm -f /tmp/claude-cam-snap.jpg`
4. Uninstall the plugin: run `claude plugin uninstall claude-permission-light`
5. Tell the user: "Claude Permission Light uninstalled. imagesnap was kept — remove it manually with `brew uninstall imagesnap` if you no longer need it."
