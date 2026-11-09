# Verification record — 2026-11-03

## Host behavior tests

Command: `python tests/run_tests.py` from master.

Result: PASS, eight C++ executables, zero failures. Compiler: MSVC 14.51.

| Executable | Covered behavior |
| --- | --- |
| test_audio | Silent playback failure, ongoing status deadline, query frame, timer rollover |
| test_color | Normalized RGB classifications, invalid calibration, no-target/timeout/ambiguity |
| test_combined | Audio readiness/verification, pump ACK, cancellation, relay2 independence, link failure |
| test_controller | Modes, lighting rules, sound hold, joystick, stale telemetry, debounce, rollover |
| test_feedback | App poll freshness, bounded log, LCD row clipping/padding, JSON escaping, mode restriction |
| test_link | Handshake, retries, duplicate/reordered commands, expired sessions, retired discovery, ACK/telemetry ordering |
| test_motor | Actual motor .ino adapter, assigned pins, zero PWM before reversal, stop/startup |
| test_protocol | Packet size/version/type/field validation, session validation and rollover |

Runner verifies master/slave copies of miniature_protocol.h, reliable_link.h and
feedback.h are byte-identical. Most feature tests were observed failing before
implementation; review regressions were observed failing before their fixes.

## ESP32 builds

Bundled Arduino CLI 1.5.1, installed `esp32:esp32` core 3.3.12. Libraries:
Adafruit NeoPixel 1.15.5, DFRobotDFPlayerMini 1.0.6, LiquidCrystal_I2C 2.0.0.
Provisional target
`esp32:esp32:esp32` (generic ESP32 Dev Module); actual board models remain unconfirmed.

Commands from master, with bundled CLI executable replacing `arduino-cli`:

```powershell
arduino-cli compile --fqbn esp32:esp32:esp32 --jobs 2 --libraries ../libraries --build-path .build/master .
arduino-cli compile --fqbn esp32:esp32:esp32 --jobs 2 --libraries ../libraries --build-path ../slaveminiature/.build/slave ../slaveminiature
```

Both commands completed with exit code 0 after the review corrections.

| Sketch | Flash | Static RAM |
| --- | --- | --- |
| Master | 976416 / 1310720 bytes (74%) | 50848 / 327680 bytes (15%) |
| Slave | 922184 / 1310720 bytes (70%) | 47448 / 327680 bytes (14%) |

Slave build warning: LiquidCrystal_I2C architecture compatibility metadata warns
about ESP32. It compiled successfully; actual LCD behavior is still a bench check.
Build output and executables live under ignored .build directories.
`tests/build.ps1` provides equivalent repeatable builds (its build folders differ).

## Review

Independent review found HTTP/watchdog blocking, silent DFPlayer failures,
ACK/telemetry status ordering and receive-before-expiration issues. Corrections:
separate HTTP task with queued controller actions and mutex-protected snapshots;
bounded asynchronous playing-state probes; command watermark on telemetry/ACKs;
expiry before queue processing plus receive timestamps. Regression tests cover
portable ordering/audio logic. HTTP task scheduling and I2C/UART timing still need
the real-device acceptance checks; builds do not prove physical behavior.

## Pending physical verification

No hardware was flashed or operated. Run ../bench-checklist.md for board/pin
validation, boot straps, relay/RGB polarity, NeoPixel counts, color calibration,
DFPlayer compatibility/playback, slow HTTP client behavior, radio loss, LCD updates,
pump flow and mechanical flag travel. No limit switches or automatic endpoint
protection have been added.

## IR diagnostics update — 2026-11-03

Added transition/periodic serial logs for slave raw IR/polarity/detection, master
received IR/freshness/mode/RGB decision, and commanded RGB pin PWM values. Sensor
polarity and control behavior were preserved; no hardware fault has been diagnosed
or claimed fixed. No new tests were added for the diagnostic-only change.

Both sketches compiled again with the same ESP32 core/target and exit code 0:
master 977140 bytes flash / 50864 bytes RAM; slave 922444 bytes flash / 47464 bytes RAM.
An initial master rebuild hit a file lock in the existing build folder; retry in
`.build/ir-master` succeeded. Slave retains the library architecture warning above.
Upload both updated sketches, open Serial Monitor at 115200 and compare the three
`[IR slave]`, `[IR master]`, `[RGB master]` log prefixes while presenting/removing
an object. Actual GPIO voltage/light output still requires bench verification.

## Sound diagnostics update — 2026-11-03

Added `[Sound slave]` raw/active/pulse/latch logs and `[Sound master]` received-event,
freshness/mode/building-decision logs, with 100 ms event/change rate limiting and
2-second periodic summaries. No sensor polarity or controller hold behavior changed.
The user's existing local slave pin swap (IR=4, SOUND=5) was preserved and used for
this build; it is not included in the diagnostic commit.

Both builds completed with exit code 0 using the same core 3.3.12/generic ESP32 target:
master 977604 bytes flash / 50880 bytes RAM; slave 922780 bytes flash / 47472 bytes RAM.
Build directories were placed under the local temp folder to avoid OneDrive build
folder locks. The existing LiquidCrystal_I2C architecture warning remains. This is
a diagnostic-only change; no new tests or hardware-operation claims were added.
