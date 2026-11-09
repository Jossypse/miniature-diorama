# Wi-Fi integration verification - 2026-11-04

Source checkpoints: master `6ff077f`, Android app `329d6b2`, unchanged slave `34ceedb`. All repositories retain `before-wifi-integration`; master/app work remains on `feature/wifi-app-integration`. No merge, push or firmware flash performed.

## Verified

| Check | Result |
| --- | --- |
| `python tests/run_tests.py` | PASS, 12 C++ executables; shared ESP-NOW headers match |
| `python tools/check_wifi_fixtures.py --app-root C:/Users/josep/Downloads/dioramaapp` | PASS, canonical fixture copies match |
| `flutter analyze` | PASS, no issues; vendored upstream source excluded from app lint only |
| `flutter test` | PASS, 26 tests including existing intro regression, live controls, queue/volume ordering, boot-scoped motion recovery and demo navigation |
| `flutter build apk --debug --target-platform android-arm64` | PASS |
| Android USB `adb install -r` | PASS on H6WC4HGM7LGULNQO; launched com.example.dioramaapp/.MainActivity |
| Phone visual inspection | Wi-Fi connection screen checked from screenshot; no clipping on the connected phone |
| Phone-width widget navigation | PASS at390x844, including Home/Control/Flag/Music; caught/fixed header wrapping |

The single independent review identified four Important issues, all reproduced with failing regression tests then fixed. Its stale-color finding was regraded Important against the required unknown-on-stale behavior and fixed with a failing widget regression. No deferred minor findings. Whole suites were rerun after fixes.

## Artifacts and hardware limits

APK: `C:/Users/josep/Downloads/dioramaapp/build/app/outputs/flutter-apk/app-debug.apk`.
Master binaries: `.build/esp32/masterminiature.ino.bin` and `.build/esp32/masterminiature.ino.merged.bin`.
Slave compile output: sibling `slaveminiature/.build/esp32/` (compatibility verification only; slave unchanged).
Final `powershell -File tests/build.ps1`: PASS for both sketches using esp32:esp32:esp32, core3.3.12.
Master:1004792 bytes flash (76%),54320 bytes static RAM (16%).
Slave:922780 bytes flash (70%),47472 bytes static RAM (14%). The installed LiquidCrystal_I2C library emits its existing architecture metadata warning; compilation succeeds.
Release manifest: `.build/wifi-release/manifest.json`, containing source commits, artifact paths/sizes and SHA256 hashes. Master firmware SHA256 `7c987ac98a0aeb0746b4858fd13eeab1e08231236003e77dc13cbf60916b3e41`; APK SHA256 `771816d22aa5f242e3fe6693eab7455ead1ac42f03f573ca839006b6aae28f33`.
Final reviewed/fixed APK reinstalled successfully and launched; package version0.1.0, lastUpdateTime2026-11-04 10:56:41. Installation does not establish Wi-Fi hardware connectivity.

No physical ESP32 USB interface is connected. COM9 and COM10 identify as Standard Serial over Bluetooth links. The PC is connected to HeroApps_5G, not the master AP. Therefore firmware has not been flashed and phone-to-master HTTP, SD audio, GPIO behavior, relays, LCD timeout and motor stopping are explicitly pending the [bench checklist](../../wifi-app-bench-checklist.md). Software tests verify controller logic, not actual loads or electrical wiring.

Rollback: commit or stash any future edits, then `git switch --detach before-wifi-integration` in the relevant repository and rebuild/install/flash that baseline. Existing feature commits stay recoverable. To return, `git switch feature/wifi-app-integration` in master/app. The baseline slave commit preserves the user's IR4/SOUND5 assignments.
