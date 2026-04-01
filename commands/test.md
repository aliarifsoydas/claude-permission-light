Test the camera LED blink to verify it works on this machine.

Run these steps:

1. Check `command -v imagesnap` — if missing, tell user to run `brew install imagesnap` and stop
2. Start the blink: run `${CLAUDE_PLUGIN_ROOT}/bin/camera-blink.sh start`
3. Tell the user: "Camera LED should be blinking now. Watch the green light next to your webcam."
4. Wait 3 seconds with `sleep 3`
5. Stop the blink: run `${CLAUDE_PLUGIN_ROOT}/bin/camera-blink.sh stop`
6. Ask the user if they saw the LED blink

If the LED did not blink, suggest:
- Check System Settings > Privacy & Security > Camera — grant access to the terminal app
- Try `CAM_DEVICE="FaceTime HD Camera" ${CLAUDE_PLUGIN_ROOT}/bin/camera-blink.sh start` if using a virtual camera (OBS)
