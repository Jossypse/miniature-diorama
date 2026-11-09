# Miniature master + slave

Firmware for two classic ESP32 boards. Update **both sketches together**: the
versioned ESP-NOW protocol is incompatible with the baseline sketches.

## Master wiring

| Function | GPIO |
| --- | --- |
| Button 1: fountain blue toggle | 13 |
| Button 2: RGB cycling toggle | 12 |
| Button 3: building yellow toggle | 14 |
| Button 4: automatic/manual | 27 |
| Button 5: track 1 + pump 1 toggle | 26 |
| Fountain NeoPixel data | 33 |
| Building NeoPixel data | 25 |
| Motor AIN1 / AIN2 / PWM | 18 / 5 / 4 |
| RGB red / green / blue | 19 / 21 / 22 |
| DFPlayer ESP RX / TX | 17 / 16 |

Buttons connect GPIO to GND; internal pullups are enabled. GPIO12 is a boot strap
on classic ESP32: do not add an external pullup or drive it high during reset
without checking your board's boot requirements. GPIO5 is also a strap; verify
the motor module does not impose an incompatible reset level. No software STBY
signal exists: wire any driver enable/STBY as required by the actual module.
Motor driver power and ESP32 ground must be connected appropriately.

## Slave wiring

| Function | GPIO |
| --- | --- |
| Relay 1 / relay 2 | 23 / 19 |
| Joystick Y | 34 |
| IR / sound digital output | 4 / 5 |
| TCS3200 S2 / S3 / OUT | 25 / 26 / 27 |
| LCD SDA / SCL | 21 / 22 |

Joystick uses 3.3 V supply and common ground; inputs must remain ESP32-compatible.
Default LCD address is 0x27, 16x2. Relays default active-HIGH, IR active-LOW, sound
active-HIGH. Change `slave_config.h` for the actual modules before connecting loads.
TCS3200 S0/S1 are **external connections**, not GPIOs: use HIGH/LOW for 20% scaling,
then calibrate at that setting. Ensure the sensor OUT voltage suits ESP32 inputs.

## Settings and behavior

Master settings are in `master_config.h`; slave settings in the sibling sketch's
`slave_config.h`. NeoPixels use Adafruit_NeoPixel, GRB/800 kHz, brightness 50 and
30 pixels **per strip** initially. Set each real pixel count. Power strips from
an appropriate external supply, with common ground and suitable data level
conversion where required; GPIO data pins do not power strips. RGB streetlights
remain separate three-channel PWM outputs, with common-anode configuration available.

Boots in automatic mode. Valid color selects red/green/blue/yellow/white fountain
lighting; no valid color turns it off. IR presence cycles streetlight RGB; absence
turns it off. Sound lights buildings yellow for 2 seconds, extended by new sound.
Buttons 1–3 work in manual mode, with 30 ms debounce and one action per press.
A button held at boot must first be released. Mode changes clear manual lighting
and stop the motor. Joystick works only in manual mode, below 1000/above 3000,
stopping in the middle. Change thresholds/direction in master config.

**Flag travel is not endpoint-protected.** No limit switches are assigned; establish
physical limits or another verified travel bound before operating a loaded flag.
The 1-second stale-telemetry stop protects against link loss, not hitting endpoints.

Button 5 and the app's Sound + Fountain work in either mode. They start track1 and a dancing fountain: pump1 runs for4seconds, then pump2 for4seconds, repeating while the audio plays. Each phase waits for the previous relay acknowledgment and only one pump is commanded ON. A second press stops both pumps and audio. Pause, stop, playback replacement, completed audio, audio failure or link loss cancel the show and turn both pumps off. A legacy browser/API relay command cancels the show before applying its explicit manual pump setting. Volume changes leave the show running. The app has no separate pump buttons; fountain LED lighting remains a separate control. `FOUNTAIN_STEP_MS` in master_config.h sets the4second interval.

Runtime DFPlayer commands use
ACK-disabled writes to avoid its library's acknowledgment wait. Asynchronous state
queries begin after 100 ms and repeat every 250 ms; the combined action becomes
active only after pump acknowledgment and a playing-state response. Missing playing
responses for 1 second stops the combined action and marks audio unavailable.
"Playback requested" and playing-state feedback do not prove audible sound.
Its library still imposes a bounded 10 ms command
delay, and a bounded startup probe occurs before networking/motion is enabled.
Use an SD card with `/mp3/0001.mp3` and `/mp3/0002.mp3` for the web tracks.

## Connection and control page

Connect to Wi-Fi `ESP32_Master_Diorama`, password `password123`, then open
`http://192.168.4.1/`. Status polls each second; app offline means no poll for
5 seconds. LCD reports the master link and app separately and alternates relay
outputs with the latest event. Web controls use the same mode/actuator controller.
Confirmed relay output means commanded electrical output, **not confirmed water flow**.
HTTP runs in its own RTOS task. That task only queues actions and reads a locked
status snapshot; all controller/peripheral mutations run on the main task. Slow
HTTP request parsing cannot block the main loop's motor/link watchdog. Status
snapshots refresh every 100 ms; queued web requests are revalidated in the controller.

Both radios use channel 1 and station-interface peer MACs. Check boot serial output
at 115200 and edit `SLAVE_MAC` / `MASTER_MAC` if necessary. The master's SoftAP MAC
is different from its STA MAC. No router association is needed.

Telemetry/heartbeats are sent every 200 ms. Master stops motion/automatic lights
on 1 second of stale telemetry; slave turns both pumps off after 1 second without
valid master heartbeats. Pump commands retry at 250 ms up to three retries, then
force a link reset so the slave watchdog can turn outputs off. Reconnect never
replays pending ON commands; press a control again after link recovery.

## IR / RGB diagnostics

Upload the updated sketches to both boards and open each Serial Monitor at 115200.
`[IR slave]` prints GPIO5's raw HIGH/LOW reading, configured active level, normalized
detection and master-link state. Default active-LOW means raw LOW is detected.
`[IR master]` prints the received detection, telemetry freshness/age, selected mode,
RGB enable and the reason for it. `[RGB master]` prints the actual PWM values sent
to GPIO19/21/22 and common-cathode/anode configuration. These are commanded outputs,
not measured voltages. Logs print transitions, rate-limited to 100 ms, and a summary
every 2 seconds while their service runs; RGB PWM logs also print as the cycle runs.

In AUTO with an object, expect slave `detected=YES`, master `telemetry=FRESH` and
`RGB=ON reason=IR_DETECTED`, followed by changing RGB PWM values. If slave raw never
changes, check sensor wiring/adjustment; if telemetry is missing check peer MACs/link;
if the commanded PWM changes but lights remain dark, inspect RGB wiring, polarity,
power and any required drivers. These logs diagnose the fault without changing
sensor polarity or light behavior.

## Sound diagnostics

At 115200 baud, `[Sound slave]` reports the actual configured sound GPIO, raw level,
trigger polarity, instantaneous trigger, any captured pulse since the last log,
and whether a sound event is latched for telemetry. `[Sound master]` reports sound
events received since the last log, telemetry freshness, mode and the building
strip decision/GPIO. In AUTO expect `receivedSinceLog=TRIGGER`, `building=ON` and
`reason=SOUND_HOLD_2000MS`; the strip turns off 2 seconds after the last reported
trigger. Persistent triggers extend the hold. Manual mode ignores sensor lighting
requests. Check the current slave_config.h for pin assignments; diagnostics print
the configured pins rather than assuming the original wiring table.
Messages are limited to 100 ms on changes/events and repeat at least every 2 seconds
while the main loop runs. Captured short sound pulses are retained for the next log.

## Color calibration

Read slave serial lines `TCS us R=... G=... B=... color=...` at 115200. Keep target
distance, lighting, supply and S0/S1 scaling fixed. Record each channel's pulse
duration for a white reference and for a dark/no-target reference; put them in
`ColorCalibration.whiteUs[]` and `darkUs[]` in `slave_color.h`. Defaults 50/1000 us
are starting values, not measurements of your sensor. White periods must be
positive and shorter than dark periods. Test all five target colors and absence;
adjust `minTarget` and `dominance` only after calibration. Supported class IDs:
0 none, 1 red, 2 green, 3 blue, 4 yellow, 5 white. Ambiguous/timeout samples become
none. Each pulse read is capped at 3 ms; filter changes settle for 5 ms between
loop iterations. Increase timeout only with awareness of watchdog latency.

## Build and tests

Open each folder's matching `.ino` in Arduino IDE. Install ESP32 by Espressif,
Adafruit NeoPixel, DFRobotDFPlayerMini and LiquidCrystal_I2C. Compile target used
locally is **ESP32 Dev Module (`esp32:esp32:esp32`), core 3.3.12**, pending confirmation
of the actual board model. Current receive callback needs Arduino ESP32 3.x.

Run `python tests/run_tests.py` from master for the portable C++ behavior suite.
It uses MSVC Build Tools; set `VCVARS64` to your `vcvars64.bat` if installed elsewhere.
The runner also verifies duplicated protocol/link headers are identical. Hardware
adapters are checked by actual ESP32 compilation and the bench checklist, not by
host simulation. See [bench checklist](docs/bench-checklist.md) before flashing.
`powershell -File tests/build.ps1` compiles both sketches; use `-Fqbn` and
`-ArduinoCli` to override target and local CLI location.

## Local history and rollback

Both folders have independent Git repositories. `baseline-before-features` records
the original sketches with the latest user pin changes. Implementation is on
`feature/miniature-functions`; main remains the original baseline.
Inspect with `git diff baseline-before-features` in either folder. To view baseline
without discarding implementation commits, first commit/stash any new work, then
`git switch main` **in both folders**. Switch back with
`git switch feature/miniature-functions`. No changes are uploaded or flashed automatically.

## Android Wi-Fi integration

See [API v1](docs/wifi-api-v1.md) and [bench checklist](docs/wifi-app-bench-checklist.md). Upload the updated master sketch; the existing ESP-NOW v1 slave remains compatible. Android uses typed status and command results at 192.168.4.1.

## Manual flag motor entry guard

Entering manual mode does not accept an already-held joystick direction. The joystick must stay inside the neutral dead zone for250ms before a subsequent deflection can move the flag. Mode changes, stale/invalid joystick telemetry and link recovery reset this guard. Explicit app hold-to-move commands remain available with fresh telemetry; once armed, deliberate joystick movement still overrides an app hold.
