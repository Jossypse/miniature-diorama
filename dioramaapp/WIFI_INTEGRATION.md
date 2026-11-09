# Device Wi-Fi integration

1. Upload the updated masterminiature sketch to the master ESP32. Keep the existing ESP-NOW v1 slave and its configured MAC/pins.
2. Join **ESP32_Master_Diorama**, password **password123**, from Android Wi-Fi settings. Keep the network when Android reports no Internet.
3. Open the app and tap **Connect**. Local HTTP is permitted only for 192.168.4.1 in the Android network security config.

Home mirrors reported mode, sensors and recent device logs. Control separates fountain lights, RGB streetlights, building lights, combined sound+pump1, pump1 and pump2. Lighting requires manual mode. Flag uses hold/release with a five-second cap; position is unavailable. Music uses SD tracks1/2 and actual device playback state; durations are unavailable. Bluetooth, phone playback and narration are unavailable in this release. Continue offline enables explicit simulation only.

The app polls API1 every second with a two-second timeout and one request in flight. It never retries an actuator POST. Pending results are followed with read-only queries; uncertainty is shown without inventing success. First failed status makes controls stale; two failures show offline. Recovery, foreground return and master reboot refresh state without replaying actions. Flag renewals stop on release, navigation, stale data, background or joystick takeover. Music queue transitions require fresh completion in the same connected foreground session.

Build: `flutter test`, `flutter analyze`, `flutter build apk --debug --target-platform android-arm64`. APK: `build/app/outputs/flutter-apk/app-debug.apk`. The pinned upstream Bluetooth plugin is retained for build compatibility but its transport is disabled; upstream source is excluded from application lint analysis.

Local baseline tag: `before-wifi-integration`. Feature history: `feature/wifi-app-integration`. To inspect rollback safely, commit current changes then `git switch --detach before-wifi-integration`; rebuild/install that version. No remote push or merge is required.

Firmware API and physical bench checklist are in the master repository under docs/wifi-api-v1.md and docs/wifi-app-bench-checklist.md. Physical behavior still needs verification after master upload; passing software tests does not verify connected pumps, wiring, SD audio or flag travel.
