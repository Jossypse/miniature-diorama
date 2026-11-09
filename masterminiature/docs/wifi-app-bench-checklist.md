# Wi-Fi bench checklist

Software checks are recorded in implementation/wifi-app/verification.md. These physical checks require the matching master firmware and actual connected loads. Unchecked items are pending, not inferred from unit tests.

- [ ] Upload masterminiature to the correctly identified master ESP32; preserve configured peer MAC addresses.
- [ ] Slave is online with IR GPIO4 and SOUND GPIO5; matching ESP-NOW v1 firmware and channel 1.
- [ ] Android joins ESP32_Master_Diorama/password123 and keeps the connection without Internet; app Connect shows current hardware state.
- [ ] Automatic color-to-fountain, IR-to-RGB and sound-to-building work; short sound is visible between app polls.
- [ ] Manual blue fountain, yellow building and RGB cycle work from app and physical buttons; each change reconciles in the app/LCD.
- [ ] Buttons4/5 update mode/combined state; rapid mode changes reject an already queued forbidden light command.
- [ ] Independent pumps1/2 confirm after ACK, including slave loss/reconnection. Combined starts track1+pump1; pause/stop/independent audio/pump1 cancels combined without changing pump2.
- [ ] SD tracks1/2, pause/resume/stop and volume work; natural completion advances queued audio exactly once; errors do not advance it.
- [ ] App hold raise/lower: release, cancel, tab exit and background stop promptly. Wi-Fi loss stops by lease expiry; continuous hold stops by5s.
- [ ] Joystick overrides app hold; centering does not resume the old hold. Flag position stays unknown.
- [ ] Master reboot invalidates old requests; reconnect/background completion does not replay audio or other actions.
- [ ] Slow HTTP client leaves physical buttons, joystick, ESP-NOW and leases responsive.
- [ ] LCD app indication disappears within5s after polling stops.

Rollback: in each repository `git switch --detach before-wifi-integration` checks out the saved baseline without deleting feature history. Rebuild/reinstall or reflash that baseline as needed. Keep changes committed before switching. Do not reset or delete the feature branch.
