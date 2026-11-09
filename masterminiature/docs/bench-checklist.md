# Bench acceptance checklist

All physical checks below are pending until performed on the actual boards.

- [ ] Confirm both board models and compile target; verify all pin connections against README/configs.
- [ ] Set actual NeoPixel counts; verify GRB colors at brightness 50 with external power.
- [ ] With loads disconnected, confirm relay polarity and OFF output at startup/reset.
- [ ] Check driver enable/STBY, motor direction and verified flag travel bounds before loaded operation.
- [ ] Confirm both STA peer MACs and channel 1 using serial boot messages.
- [ ] Wire external TCS S0/S1 scaling; calibrate white/dark at fixed distance and lighting.
- [ ] Present red, green, blue, yellow and white: fountain shows matching color; remove target: OFF.
- [ ] Unplug TCS OUT: no false color; link and watchdog remain responsive.
- [ ] IR target present: RGB cycles smoothly; remove target: OFF.
- [ ] Sound pulse: building yellow for 2 seconds; repeated sound extends; quiet: OFF.
- [ ] Manual mode: B1 blue fountain toggle, B2 RGB cycle toggle, B3 yellow building toggle.
- [ ] Hold each button: only one action; hold during reset: no action until release/repress.
- [ ] B4 changes mode; lights reset; sensor rules resume in auto; manual buttons/web lighting rejected in auto.
- [ ] Manual joystick: up/down direction correct, center stops; automatic mode never moves motor.
- [ ] B5 starts track1 plus relay1, then stops both; repeat rapidly while command pending.
- [ ] Independent audio/relay1 web action cancels combined show before applying new command; relay2 remains independent.
- [ ] Natural track completion, missing SD, removed card and player-reported errors stop combined pump action.
- [ ] Disconnect DFPlayer UART/power after boot: combined action stays pending, fails within the 1-second audio deadline, and requests pump OFF. Repeat while playback is already active.
- [ ] Verify tracks at `/mp3/0001.mp3` and `/mp3/0002.mp3`; web audio stop works.
- [ ] LCD shows master link/app freshness, mode, relay states and recent function/button events without repeated clear flicker.
- [ ] Close control page: app offline within 5 seconds plus heartbeat/update latency; master link remains online.
- [ ] Stop/reset slave while joystick moves: master motor stops within 1-second timeout plus bounded loop latency.
- [ ] Stop/reset master while pump runs: slave outputs OFF within 1 second plus bounded loop latency.
- [ ] Reconnect either board: pumps stay OFF until a fresh user action; no replayed ON.
- [ ] Drop pump acknowledgment packets: pending/retry/failure displayed; watchdog eventually turns outputs OFF.
- [ ] Verify one-way radio loss and both-board resets; stale/unknown status must not look like confirmed OFF.
- [ ] While the joystick runs the motor, open a TCP socket to port80 and send an incomplete `GET /` request without CRLF; disconnect slave. Motor timeout must still operate while HTTP worker waits.
- [ ] Check browser page polling, status JSON, recent event log, failed audio/pump messages and manual mode restriction.

Host tests cover malformed fields, duplicate/out-of-order commands and timer rollover;
hardware testing additionally establishes electrical behavior, pulse timing, color
accuracy, pump flow and mechanical travel. Record board/core/library versions,
calibration, observations and date when executing this list.
