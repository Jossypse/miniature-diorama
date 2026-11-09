# Manual mode flag guard

Reported trigger: switching to Manual from the Android app starts the flag motor without a movement request.

Investigation: app mode setter sends only mode.set(false). Firmware immediately accepted any joystick reading outside1000..3000 when manual became active. Current live samples were centered around1740..1780; a brief live manual transition remained stopped with owner none, then original automatic mode was restored. Thus the current physical incident did not recur during that sample, but a regression with a joystick already at3500 reproduced the immediate mode-entry movement in the actual controller logic.

Fix: central Controller joystick-direction helper requires250ms stable neutral after manual entry or stale/invalid telemetry. Both the physical output arbiter and command arbitration use that same gate. Deliberate app holds remain explicit movement requests, while a subsequently armed joystick retains takeover priority. No pin, slave protocol, app or fountain behavior changes.

Regression test_mode_motor_guard.cpp observed RED before change, then GREEN for held input on mode entry, interrupted neutral dwell, explicit app movement, joystick takeover/release, telemetry loss/recovery and millis rollover. Existing movement tests now establish the required neutral dwell before asserting deliberate joystick movement. Full host suite15/15 passed. Master compiled successfully:1006804 bytes flash(76%),54376 bytes static RAM(16%). Uploaded/flash-hash-verified on COM13 at115200baud to MAC40:22:D8:33:C5:40.


Live verification after upload (boot35ad2e0d): three Automatic-to-Manual transitions, eight samples each. All24 samples reported motor stopped and owner none, with joystick readings1727..1775. Original automatic mode restored after the automated check. No flag movement command was sent. User then switched Manual in the app and explicitly confirmed the physical motor stays stopped until a deliberate movement request.

Source checkpoint40abc79; verified image and SHA256 manifest under .build/manual-flag-guard/. Detailed live samples .build/manual-flag-live-verification.json; upload log .build/manual-flag-upload.log. App/slave unchanged, original Music UI and dancing fountain retained.
