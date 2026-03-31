# Claude Permission Light

Blinks the MacBook camera LED when Claude Code asks for permission. A physical notification so you never miss a permission prompt -- even when you are not watching the terminal.

macOS only. Bash only. No complicated setup.

## How It Works

When Claude Code needs your permission (to edit a file, run a command, etc.), it fires a Notification hook. This tool catches that hook and starts blinking your camera LED. When you respond to the prompt, a Stop hook turns the blink off.

The camera LED is hardwired to the camera sensor on MacBooks -- when the camera activates, the LED turns on. This tool uses `imagesnap` to briefly activate the camera in a loop, creating a visible blink pattern.

The blink also self-terminates after 60 seconds as a safety measure, so the camera never runs indefinitely.

## Requirements

- macOS 13 (Ventura) or later
- [Homebrew](https://brew.sh)
- Claude Code v2.1.85+

## Install

```bash
git clone <repo-url>
cd claude-permission-light
./install.sh
```

This will:
1. Install `imagesnap` and `jq` via Homebrew (if not already installed)
2. Add Notification and Stop hooks to `~/.claude/settings.json`
3. Trigger the macOS camera permission dialog (grant access when prompted)

The install is idempotent -- safe to run multiple times.

### Verify Installation

```bash
./bin/status.sh
```

You should see `[OK]` for imagesnap and both hooks. The blink process line shows `[--]` when idle, which is normal.

## Uninstall

```bash
./uninstall.sh
```

Removes hooks from `~/.claude/settings.json`, stops any running blink process, and cleans up state files. Does not remove `imagesnap` or `jq`.

## Manual Setup

If you prefer not to run `install.sh`, configure the hooks yourself:

1. Install dependencies:

```bash
brew install imagesnap
```

2. Add hooks to `~/.claude/settings.json`. If the file does not exist, create it. Merge the `hooks` object into any existing configuration:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/bin/permission-signal.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/bin/permission-cleanup.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `/absolute/path/to` with the actual path to this repository on your machine.

3. Grant camera access. Run this once and approve the macOS permission dialog:

```bash
imagesnap -w 0 /tmp/test.jpg
rm /tmp/test.jpg
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CAM_BLINK_INTERVAL` | `1` | Blink cycle time in seconds (on + off) |
| `CAM_DEBUG` | `0` | Set to `1` to enable debug logging to stderr |
| `CAM_DEVICE` | auto-detect | Camera device name (defaults to FaceTime camera) |

Example -- blink faster:

```bash
export CAM_BLINK_INTERVAL=0.5
```

## Troubleshooting

Run `./bin/status.sh` first. It checks all three components (imagesnap, hooks, blink process) and reports `[OK]` or `[FAIL]` for each.

### Camera permission denied

**Symptom:** Blink does not work. `status.sh` shows imagesnap OK but there is no visible LED.

**Fix:** Open System Settings > Privacy & Security > Camera. Grant access to your terminal app (Terminal, iTerm2, Warp, etc.). Then test with:

```bash
imagesnap -w 0 /tmp/test.jpg && rm /tmp/test.jpg
```

### imagesnap not found

**Symptom:** `[FAIL] imagesnap not installed` in `status.sh` output.

**Fix:**

```bash
brew install imagesnap
```

### Hooks not configured

**Symptom:** `[FAIL] Notification hook not found` or `[FAIL] Stop hook not found` in `status.sh` output.

**Fix:** Run `./install.sh` or follow the Manual Setup section above.

### Blink does not stop after responding

**Symptom:** LED keeps blinking after you approve or deny the permission prompt.

**Cause:** Claude Code fires the Stop hook when the session task completes, not immediately when you respond. There may be a slight delay.

**Note:** The blink self-terminates after 60 seconds as a safety measure, so it will always stop eventually.

### Multiple Claude Code sessions

**Symptom:** Blink behavior seems inconsistent with multiple sessions open.

**Note:** Only one blink process runs at a time. A new permission prompt reuses the existing blink or replaces it. This is expected behavior.

## Project Structure

```
bin/
  camera-blink.sh        # Core blink engine (start/stop)
  permission-signal.sh   # Notification hook entry point
  permission-cleanup.sh  # Stop hook entry point
  status.sh              # Diagnostic tool
lib/
  common.sh              # Shared constants and utilities
install.sh               # One-command setup
uninstall.sh             # One-command teardown
.claude-plugin/
  plugin.json            # Claude Code plugin manifest
hooks/
  hooks.json             # Plugin hook definitions
```

## License

MIT
