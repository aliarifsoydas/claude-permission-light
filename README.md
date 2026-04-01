# Claude Permission Light

Blinks the MacBook camera LED when Claude Code asks for permission. A physical notification so you never miss a permission prompt -- even when you are not watching the terminal.

macOS only. Bash only. No complicated setup.

## How It Works

When Claude Code needs your permission (to edit a file, run a command, etc.), it fires a Notification hook. This tool catches that hook and starts blinking your camera LED. When you respond to the prompt, a Stop hook turns the blink off.

The camera LED is hardwired to the camera sensor on MacBooks -- when the camera activates, the LED turns on. This tool uses `imagesnap` to briefly activate the camera in a loop, creating a visible blink pattern.

The blink also self-terminates after 10 minutes as a safety measure, so the camera never runs indefinitely.

## Requirements

- macOS 13 (Ventura) or later
- [Homebrew](https://brew.sh)
- Claude Code v2.1.85+

## Install

### Option 1: Plugin Install (Recommended)

```bash
brew install imagesnap
claude plugin marketplace add https://github.com/aliarifsoydas/claude-permission-light.git
claude plugin install claude-permission-light@claude-permission-light
```

Done. Start a new Claude Code session and the LED will blink on permission prompts.

### Option 2: Git Clone + Script

```bash
git clone https://github.com/aliarifsoydas/claude-permission-light.git
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
# If installed via plugin:
imagesnap -w 0 /tmp/test.jpg && rm /tmp/test.jpg   # grant camera access on first run

# If installed via git clone:
./bin/status.sh
```

You should see the camera LED flash briefly during the test capture.

## Uninstall

```bash
# Plugin install:
claude plugin uninstall claude-permission-light

# Git clone install:
./uninstall.sh
```

Removes hooks, stops any running blink process, and cleans up state files. Does not remove `imagesnap`.

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

**Fix:** Run `/claude-permission-light:setup fix` to kill a stuck blink process. The PreToolUse hook should stop the blink automatically when permission is granted. If it persists, the blink self-terminates after 10 minutes as a safety measure.

### Multiple Claude Code sessions

**Symptom:** Blink behavior seems inconsistent with multiple sessions open.

**Note:** Only one blink process runs at a time. A new permission prompt reuses the existing blink or replaces it. This is expected behavior.

## Plugin Commands

If installed via plugin, these slash commands are available in any Claude Code session:

| Command | Description |
|---------|-------------|
| `/claude-permission-light:status` | Check installation health |
| `/claude-permission-light:test` | Test LED blink on real hardware |
| `/claude-permission-light:setup check` | Check dependencies |
| `/claude-permission-light:setup install` | Install missing dependencies |
| `/claude-permission-light:setup fix` | Diagnose and fix common issues |
| `/claude-permission-light:uninstall` | Stop blink, clean state, remove plugin |

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
