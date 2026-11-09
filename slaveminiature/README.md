# Miniature slave

Sensors, LCD and two pump relays for the paired `masterminiature` sketch.
Update both boards together; packet format changed from the baseline.

| Component | GPIO |
| --- | --- |
| Relay1 / Relay2 | 23 / 19 |
| Joystick Y | 34 |
| IR / sound | 5 / 4 |
| TCS3200 S2 / S3 / OUT | 25 / 26 / 27 |
| LCD SDA / SCL | 21 / 22 |

Edit `slave_config.h` for peer STA MAC, channel, relay/sensor polarity and LCD address.
TCS S0/S1 are externally wired (HIGH/LOW for 20% scaling); calibrate pulse durations
in `slave_color.h`. Defaults are starting values, not hardware measurements.
Serial 115200 prints raw RGB pulse times for calibration. ESP32 inputs must not
receive voltages beyond their rating; use appropriate module supply/level conversion.

Relays default active-HIGH and OFF at boot/link loss. Both turn OFF after one second
without valid master heartbeats; reconnect requires a fresh pump action. Confirm
polarity without loads before operation. GPIO5 boot level must suit the actual board.

Build with Arduino ESP32 3.x, WiFi/ESP-NOW and LiquidCrystal_I2C. Provisional local
target: generic ESP32 Dev Module, core 3.3.12; confirm actual board model before flashing.
Shared `miniature_protocol.h`, `reliable_link.h` and `feedback.h` must stay synchronized
with the master copies. Master tests validate the portable slave logic too.

Full behavior, calibration, master wiring, tests and acceptance procedure:
`../masterminiature/README.md` and `../masterminiature/docs/bench-checklist.md`.
Both Git histories retain `baseline-before-features`; implementation branch is
`feature/miniature-functions`. No flashing is performed automatically.
