# CODEX_HANDOFF

Updated: 2026-11-05, Asia/Manila. Read before changing code or operating the hardware.

## 1. Resume summary and exact next task

**The latest requested fix is complete.** Enabling Manual from the Android app no longer starts the flag motor from an already-held joystick reading. Master firmware was uploaded and flash-hash-verified, three live mode-transition checks passed, and the user explicitly confirmed: **"Yes, it stays stopped."**

There is **no unfinished implementation step or upload for that request**. The user then requested this handoff. Do not redo the implementation, install an older image, redesign Music again, or invent a new feature.

The remaining diagnostic follow-up, if continuing the earlier audio investigation, is exactly:

1. Read `/api/v1/status`, especially `audio` and `audio.diagnostics`, **before resetting, reflashing, reseating the SD card, or issuing stop/play commands**.
2. If the intermittent idle audio error is present, save the retained raw type/command/value/time and interpret it using the installed DFRobot library. Those details were unavailable during the original failure.
3. Reproduce that specific fault in a regression before changing recovery/error classification. A restart was a temporary recovery, not a root-cause fix. Do not blindly bypass `audio.ready`.
4. If no fault is present, leave the working system alone and wait for the user's next request/recurrence. The initiating cause remains unknown.

Section 10 contains exact read-only commands to run first. Build/upload/actuator commands are separate and conditional, not required merely to resume.

## 2. Original goal and subsequent requirements

Build a functioning interactive miniature/diorama with **two ESP32 boards** and a **Flutter Android app**. Initially: review both sketches, establish pinouts and local rollback history, then implement missing/partial features:

- Color sensor -> fountain NeoPixel strip displays detected color.
- IR object detection -> independent RGB color cycling; clear -> off. RGB does not follow the color sensor.
- Sound -> building NeoPixel lights, with a 2000 ms hold.
- Master Buttons 1/2/3 manually toggle blue fountain lights, RGB cycling, yellow building lights.
- Button 4 changes automatic/manual; Button 5 controls sound plus fountain pumps.
- Joystick raises/lowers flag. LCD shows link/app state and function/event logs. DFPlayer/speaker plays device audio.
- Connect Android over **Wi-Fi first**, retaining physical controls, browser page and original visual identity. Bluetooth/cloud/phone playback are outside current scope.

Later user requirements override older plans:

1. **Restore the original Music UI.** Done; preserve it.
2. Audio must play on the **diorama speaker**, not the phone. User explicitly clarified this.
3. Alternate both fountain pumps every approximately 3-5 seconds. Implemented as **4000 ms per pump**.
4. Remove separate Pump 1/Pump 2 buttons **from Android**. Sound + Fountain is its pump control. Fountain LED lighting remains separate.
5. Entering Manual in the app must not automatically start the flag motor. Fixed and physically confirmed.

## 3. Repositories, history and tools

These are independent repositories, not a monorepo:

| Repository | Absolute path | Branch | HEAD before handoff |
| --- | --- | --- | --- |
| Master/current workspace | `C:/Users/josep/OneDrive/OneDriveFiles/Arduino/masterminiature` | `feature/wifi-app-integration` | `471a51f` |
| Slave | `C:/Users/josep/OneDrive/OneDriveFiles/Arduino/slaveminiature` | `feature/miniature-functions` | `34ceedb` |
| Android app | `C:/Users/josep/Downloads/dioramaapp` | `feature/wifi-app-integration` | `8ada1ff` |

All three trees were clean before creating this file. No push/merge was performed. The user values local Git history and dislikes unnecessary repeated approvals. Preserve existing changes and named sketch folders.

`before-wifi-integration` exists in all three repos. Firmware also has `baseline-before-features` and `features-implemented`. App Wi-Fi baseline `59ed30c` already includes initial Android setup fixes. Slave baseline preserves user **IR=4 / SOUND=5** assignments; do not undo them.

| Commit/repo | Meaning |
| --- | --- |
| Master `3ccb6fc` | Approved Wi-Fi design/plan checkpoint |
| Master `89c8e26`, `621d0f4` | Portable API/controller and actual HTTP/hardware integration |
| Master `6ff077f` | Relay supersession and boot-scoped motion-counter fixes |
| Master `fa9aece` | Persistent DFPlayer diagnostics |
| Master `1c3b5cf`, `9cd67ab` | Dancing fountain source and physical verification |
| Master `40abc79` | Latest flag motor guard source, currently flashed |
| Master `471a51f` | Latest guard verification record; docs only after source commit |
| App `59ed30c` | Local pre-Wi-Fi baseline |
| App `ebb30e4`, `329d6b2` | Integration and queue/motion/lifecycle fixes |
| App `bcb367c` | Original Music layout restored |
| App `fbd5054` | Blocked playlist taps explain unavailable audio |
| App `8ada1ff` | Four Control tiles, dancing-fountain demo; installed APK source |
| Slave `34ceedb` | Latest source, user IR4/SOUND5 checkpoint |

Tools, using explicit paths because existing shell PATH can be stale:

- PowerShell on Windows. Python `python` works; installation is under `C:/Python314`.
- Arduino CLI: `C:/Users/josep/AppData/Local/Programs/Arduino IDE/resources/app/lib/backend/resources/arduino-cli.exe`.
- Arduino IDE 2.3.10; ESP32 core **3.3.12**; FQBN **`esp32:esp32:esp32`**.
- Libraries: sibling `Arduino/libraries`: ArduinoJson 7.4.3, Adafruit NeoPixel 1.15.5, DFRobotDFPlayerMini 1.0.6, LiquidCrystal_I2C 2.0.0.
- Flutter **3.47.9**, Dart **3.13.7**: `C:/Users/josep/development/flutter/bin/flutter.bat` and `dart.bat`.
- Android SDK: `C:/Users/josep/AppData/Local/Android/Sdk`; ADB in `platform-tools/adb.exe`.
- Java: `C:/Program Files/Android/Android Studio/jbr`; NDK 28.2.13676358.
- MSVC host runner expects `C:/Program Files (x86)/Microsoft Visual Studio/18/BuildTools/VC/Auxiliary/Build/vcvars64.bat`; override via `VCVARS64` if needed.
- Python `serial`/pyserial was **not installed**. .NET `System.IO.Ports.SerialPort` was used for serial capture.

## 4. Hardware and connection details

### Master pinout

| Function | GPIO/config |
| --- | --- |
| Buttons 1/2/3/4/5 | 13 / 12 / 14 / 27 / 26; active-low to GND, pullups |
| Fountain / building NeoPixel data | 33 / 25 |
| Motor AIN1 / AIN2 / PWM | 18 / 5 / 4 |
| RGB red / green / blue | 19 / 21 / 22 |
| DFPlayer ESP RX / ESP TX | 17 / 16, UART2 at 9600 baud |
| Strips | 30 pixels each, brightness 50 |
| RGB polarity | Common cathode, `RGB_COMMON_ANODE=false` |
| Joystick neutral range | 1000 through 3000 inclusive, 12-bit readings |
| Fountain interval | `cfg::FOUNTAIN_STEP_MS=4000`, `master_config.h` |
| Joystick neutral dwell | `Controller::joyNeutralMs=250`, `master_controller.h` |

`master_sensors.ino` is a comment-only compatibility tab: sensors live on the slave. Do not reintroduce GPIO4/5 master sensors; they conflict with the motor driver.

### Slave pinout

| Function | GPIO/config |
| --- | --- |
| Relay 1 / Relay 2 | 23 / 19; active-high configuration |
| Joystick Y | 34, ADC1 |
| IR / Sound | **4 / 5**; IR active-low, sound active-high |
| TCS3200 S2 / S3 / OUT | 25 / 26 / 27 |
| TCS3200 S0/S1 | Externally wired; recommended 20% scaling HIGH/LOW |
| LCD SDA / SCL / address | 21 / 22 / 0x27; 16x2 |

Master STA MAC **40:22:D8:33:C5:40**; AP BSSID **40:22:D8:33:C5:41**. Do not confuse the AP MAC with the STA peer MAC. Configured slave MAC **B0:3F:D3:5A:F2:C4**.

ESP-NOW channel **1**; packed **35-byte v1** packet. Wi-Fi, fountain and flag fixes did not change this ABI or require a slave reflash.

Identified USB master: **COM13**, CH340 VID1A86/PID7523, actual ESP32-D0WD-V3 rev3.1. COM9/COM10 are Bluetooth virtual ports, **not USB ESP32s**. Rediscover ports; COM13 has disappeared/reappeared during work.

Android phone: **H6WC4HGM7LGULNQO**, model2311DRK48G, Android15. Package/activity **`com.example.dioramaapp/.MainActivity`**.

AP **`ESP32_Master_Diorama`**, password **`password123`**, HTTP **`http://192.168.4.1`**. Phone last used192.168.4.2. Android can switch to home Wi-Fi when the master restarts or because the AP has no Internet. An earlier timeout was proven to be the wrong phone SSID; reconnecting resolved it. Keep the no-Internet AP connection.

## 5. Completed implementation/current behavior

### Core features

- Color classification controls fountain NeoPixels in automatic mode. No valid target means no fountain light.
- IR enables independent RGB cycling. Sound enables yellow building strip with2000ms hold.
- Manual B1/B2/B3 toggle blue fountain/RGB/yellow building. B4 mode; B5 Sound + Fountain. Central mode ownership and debounce implemented.
- Raw/normalized IR, sound and RGB diagnostic logs added.
- Reliable ESP-NOW handshake, boot/session validation, ACKs, retries, duplicate/reorder handling, stale telemetry/watchdog stop and event propagation implemented.
- LCD shows `L` link, `A` app presence and AUTO/MAN. Second line alternates P1/P2 state and events. `Boot` is the boot event. App presence expires5000ms after polling stops.

### Dancing fountain

- Sound + Fountain/B5 starts SD track1 and pump1.
- Startup waits for audio and relay confirmation. Alternate pumps every4000ms measured after ACK; wait for outstanding ACK before scheduling another phase. Nonblocking and rollover-safe.
- Final show masks are1,2,0, never3. Outgoing OFF and incoming ON are queued synchronously; only the final queued packet is transmitted by the main loop after return.
- Cancel/stop/pause/completion/audio error/link failure ends the show and turns both pumps off. Pause retains paused standalone audio; resume does not silently restart pumps.
- Playback replacement cancels the show. **Volume does not cancel it.**
- A legacy browser/API relay command cancels the show **before applying its explicit setting**. Thus a deliberate manual relay ON can leave that requested pump on.
- Android has exactly four tiles: Fountain lights, Streetlights/RGB, Building lights, Sound + Fountain. No separate Pump1/Pump2 buttons. Fountain LEDs remain separate.
- User explicitly confirmed physical water-pump alternation.

### Flag and latest fix

- Mode selection is not a movement request. Manual entry clears joystick arming.
- Joystick must remain neutral250ms before a later deflection can move the motor. Mode transitions, stale/invalid telemetry and recovery reset the guard.
- `Controller::joystickDirection()` is shared by pure output logic, actual `WifiController::motor()` and API joystick arbitration. Keep these paths consistent.
- Explicit app Raise/Lower holds still work with fresh telemetry before joystick arming. An armed joystick retains takeover priority and revokes the app lease; centering never resurrects that lease.
- App renews every200ms; lease expiry1000ms; continuous hold cap5000ms. Release/cancel/tab exit/background/disconnect/stale status stop renewals and send best-effort stop.
- Motion sequences are boot-scoped and monotonic across gestures. Seed from **`motor.sequence`**, not uptime. On boot change reset local motion session without sending an old lease stop to the new boot.
- No position/endpoint sensors: `positionPercent=null`; live UI shows unavailable position, not fabricated percentages. Demo alone simulates height.
- Latest guard flashed/verified. Three live transitions,24 samples stopped/owner none, then user physically confirmed the fix.

### API and authoritative state

- `GET /api/v1/status`, `POST /api/v1/commands`, `GET /api/v1/commands/{id}`.
- Envelope `{id,bootId,action,args}`, body<=512bytes, IDs1-48 ASCII letters/digits/_/-, bootID8 lowercase hexadecimal digits.
- Explicit setters: mode.set, light.set, relay.set, combined.set, audio.play/pause/resume/stop/volume, flag.move/stop. Exact arguments: `docs/wifi-api-v1.md`.
- 202=pending, not actual success. Sixteen result slots; pending never evicted, oldest terminal can be. Same ID/payload returns existing result; changed payload conflicts; stale boot rejected.
- Main task revalidates mode/hardware at execution. Relay ON/OFF/ON supersession is irreversible; a later equal-state ACK cannot falsely complete the first superseded request.
- HTTP worker owns socket handling; bounded actions queue into Arduino task. Actuator changes stay on Arduino task. Coherent published status crosses a mutex; no socket I/O under that mutex.
- Flutter derives actual state from status, without optimistic actuator animation. Poll1s, HTTP timeout2s, one status flight. First failure stale, second offline; read-only recovery.
- Pending result polling250ms up to2500ms; no automatic POST replay after timeout, unknown result, reconnect or reboot.
- Epoch/lifecycle guards discard old replies. Internal busy key `audio_pump1` serializes audio/combined/relay1; its name is historical, combined now owns both pumps.
- Stale/offline sensors and relays are unknown/null, not false/clear/quiet; sensor label/highlight freshness is gated.
- Android network security permits local HTTP specifically to192.168.4.1.

### Music and original UI restoration

- Actual sound is **DFPlayer/device speaker**. SD files `/mp3/0001.mp3` and `/mp3/0002.mp3`.
- Original Now Playing/vinyl/playback/output-selector/two-playlist-tile layout restored at user's request. Preserve this visual identity and labels; do not restore the earlier generic track-list redesign.
- Live History tile sends track1 once; Xmas tile sends track2 once. Names are UI labels, not verified SD contents or a six-file live playlist.
- Diorama output selected; phone playback unavailable. Missing original vinyl texture replaced with rendered decoration.
- Device phases: stopped/starting/playing/paused/error. Volume0-100 maps to DFPlayer0-30. Real elapsed/duration unavailable.
- Runtime commands use ACK-disabled UART writes. Async0x42 state queries confirm playing. Natural completion requires current-track finish plus stopped-state verification and increments completionSequence once.
- MusicProvider binds once to DioramaProvider; widget build does not install duplicate command callbacks.
- Queue waits for busy audio commands, including completion observed during volume refresh. Failed/uncertain play retains the queue head and shows paused-queue error; no blind POST retry.
- Background/reconnect/new boot/missed completion does not auto-replay queue actions.
- Explicit offline demo preserves six metadata tracks, pause/resume/completion/queue, flag simulation and alternating pumps. It produces no actual phone audio. Demo timing never becomes live hardware authority.
- Blocked playlist taps now explain why instead of silently doing nothing.

### Initial Android setup

- Installed/configured Flutter/SDK/Java and corrected local SDK paths.
- Vendored `flutter_bluetooth_serial` under `third_party/`, patched legacy Gradle compatibility, retained license. Transport remains disabled for current Wi-Fi scope.
- Fixed intro ParentDataWidget assertions and flag LayoutBuilder/Positioned layout.
- Replaced obsolete MyApp counter test with real app startup/navigation tests; narrow-phone headings wrap.
- Latest arm64 debug APK built, installed and launched. Final master-only flag fix needed no app reinstall.

## 6. Architectural decisions to preserve

1. Wi-Fi phone -> master HTTP -> existing ESP-NOW slave. No cloud/Bluetooth work needed for current scope.
2. Master owns modes/local lights/motor/audio; slave owns sensors/relays/LCD. Do not reuse master motor GPIO4/5 for sensors.
3. Only Arduino control task mutates hardware; callbacks/workers queue and read published snapshots.
4. Explicit non-replayed setters, boot guards and result confirmation are intentional. Do not equate pending with success.
5. Preserve35-byte ABI/shared-header consistency unless intentionally versioning and updating both boards.
6. Four seconds is the chosen midpoint of3-5s; retune FOUNTAIN_STEP_MS if needed. Android pump-button removal leaves legacy browser/API routes intact.
7. The scheduler's synchronous relay pair depends on requestRelay only queuing. If transmission moves inside it, introduce an atomic final-mask API.
8. Stable-neutral gate must apply consistently to API arbitration and actual motor output. Repeating the current mode setter remains idempotent.
9. Preserve original Music UI and device-only audio. Bluetooth, phone playback, narration and measured flag position are unsupported scope, not completed features.
10. Maintain local rollback history and feature branches; no unsolicited merge/push/reset. Use systematic debugging and reproduce/test actual faults before speculative fixes.

## 7. Unresolved issues and stale records

### Intermittent idle DFPlayer fault: NOT FIXED

Observed `ready=false`, `state=error`, `lastError=AUDIO_UNAVAILABLE`, sometimes `trackId=null` with Audio error immediately after Boot. Direct API play returned503, proving the device also rejected playback. Restart restored sound temporarily, but it recurred while idle.

Three captured warm restarts and an idle capture did not reproduce its raw triggering error. Do not guess power, SD, wiring or parser cause. USB disappeared during a high-speed upload, but that does not prove an audio-fault cause.

Installed `audio.diagnostics` retains startupReady, event/error counts, last received frame and last error type/command/value/time/detail. These are **per-boot**, not persistent across resets/NVS. Historical diagnostic errors can remain when current audio.lastError is null; distinguish history/current state.

Current firmware makes audio unavailable on an error and recovers on card-online/insert or restart. No new autonomous recovery policy was implemented. Capture the next failure **before resetting**.

Installed DFRobot event types:0 timeout,1 malformed frame,3 card removed,6 module error. Type6 values:1 card not found,2 sleeping,3 command format,4 checksum,5 file index,6 file not found,7 advertisement. Read installed library/examples when diagnosing; every error is not necessarily disconnected hardware.

### Other limits

- No physical flag position/endpoint sensing. Lease caps do not detect endpoints.
- GPIO/ACK/playing feedback is not electrical/flow/acoustic measurement. Audible playback and physical pump alternation were user-confirmed, but contact overlap/extended electrical behavior were not instrumented.
- SD contents/durations are not verified metadata. Live catalog is1/2.
- Extended slow-client/long-duration bench matrix is not exhaustively complete. Mark actual untested items honestly.
- Builds were slow on this machine, sometimes many minutes/full SDK rebuild. Avoid redundant unrelated rebuilds; no conclusive performance-cause diagnosis was made.

### Documents with superseded snapshots

- `APP/ANDROID_SETUP.md` contains early MyApp-test failure/old-install statements. They are obsolete: current full app tests pass and updated APK is installed.
- `APP/WIFI_INTEGRATION.md` still describes separate pump buttons/single-pump combined behavior. Later user request, current code and this handoff supersede that paragraph.
- Older Wi-Fi logs/checklists say hardware absent or physical checks pending. Later fountain/guard records document actual uploads and user confirmation. Do not repeat old absence claims without rediscovering hardware.
- Browser HTML has historical pump1-only show wording; actual show alternates both. No request to remove/redesign the browser page.
- Original feature record calls board type provisional; actual master was subsequently identified as ESP32-D0WD-V3.

## 8. Tests, reviews and artifacts

These are **recorded prior results**, not tests newly rerun for this documentation request:

| Verification | Latest result |
| --- | --- |
| `python tests/run_tests.py` | PASS15/15 after flag guard; shared protocol/link/feedback headers match |
| Full Flutter tests | PASS29/29 after fountain app update; app unchanged for guard |
| Flutter analysis | No issues after final app changes; vendor source excluded from app lint, not tests |
| Fixture-copy check | PASS during integration; canonical copies remain in both repos |
| Master build | PASS core3.3.12, FQBNesp32:esp32:esp32;1006804 flash bytes(76%),54376 static RAM bytes(16%) |
| Slave compatibility build | PASS;922780 flash bytes(70%),47472 RAM bytes(14%); no later slave changes |
| APK | Arm64 debug build PASS, installed and launched |
| Latest master upload | Complete at115200 on COM13; flash hash verified, matching MAC |
| Fountain live test | Masks1->2->1 about4s each; OFF confirmed0; audio playing during show/stopped after OFF |
| Fountain physical check | User explicitly confirmed both pumps alternate |
| Flag live test | Three Manual transitions,24 samples stopped/owner none; joystick1727..1775 |
| Flag physical check | User confirmed motor stays stopped after enabling Manual |

The automated flag check restored original Auto mode; user subsequently tested Manual. **Do not assume the current live mode or connection state.**

Regressions were observed RED before fixes. Independent integration review findings fixed: relay false confirmation, queue loss during volume-refresh completion, motion sequence recovery, demo pause/resume and stale color. Independent fountain review found no blocking defect; legacy-command documentation wording was clarified.

Latest flashed master source **40abc79**; HEAD471a51f adds verification docs. Installed app source **8ada1ff**. Slave **34ceedb**.

- Latest verified master bundle: `.build/manual-flag-guard/`, including manifest and upload binaries.
- Application binary `masterminiature.ino.bin`:1006960 file bytes; SHA256 **a8f03d2a763d3af7eb5fb64c57c5a390161661340981cda325ba13a00d1889ed**. File size differs from flash-usage report.
- Upload log `.build/manual-flag-upload.log`; live samples `.build/manual-flag-live-verification.json`.
- Older `.build/dancing-fountain/` source1c3b5cf **lacks the later flag guard**. Do not restore it as newest.
- Fountain captures `.build/fountain-before.json`, `fountain-live-samples.json`, `fountain-after.json`.
- Audio captures `.build/audio-*.log` / `.json`.
- APK `C:/Users/josep/Downloads/dioramaapp/build/app/outputs/flutter-apk/app-debug.apk`; last recorded SHA256 **8444e792799b528a8a948906751997233f88a9e491fe637bc24a188f2f70ca79**.
- `.build/` and app build outputs are ignored local artifacts. Git contains source/tests/records; ignored artifacts may not exist in another clone.

## 9. Files modified and ownership

| Master files | Responsibility |
| --- | --- |
| `masterminiature.ino`, `master_config.h` | Startup/loop, pins/config/peer |
| `master_controller.h`, `master_controller.ino` | Mode/light rules, neutral gate, real output arbitration/logs |
| `master_buttons_rgb.ino`, `master_leds.ino`, `master_motor.ino` | Buttons, NeoPixel/RGB, actual motor adapter |
| `master_espnow.ino`, `reliable_link.h`, `miniature_protocol.h` | Radio queue/reliable relay transport/ABI |
| `combined_action.h`, `wifi_controller.h` | ACK-gated dancing show and API/audio/motor ownership |
| `master_audio.ino`, `audio_monitor.h` | DFPlayer adapter/async monitoring/error descriptions |
| `wifi_api.h`, `wifi_json.h`, `wifi_status.h` | Types/results/diagnostics, validation, coherent JSON status |
| `master_api_controller.ino`, `master_wifi.ino`, `web_bridge.h` | HTTP routes/worker/bridge/browser |
| `feedback.h`, `master_sensors.ino` | Logs/LCD helpers; sensor placeholder respectively |
| `tests/`, `tools/`, `docs/` | Host logic/adapter tests, builds, fixtures, specifications/verification |

App ownership:

- `lib/services/wifi_client.dart`: typed HTTP/timeout/injected test transport.
- `connection_manager.dart`: polling, epochs, result follow-up, busy keys, no POST replay.
- `flag_session.dart`: hold/renew/stop/cap and boot-scoped counter reset.
- `lib/models/device_status.dart`, `command_result.dart`, `api_command.dart`, `esp_state.dart`: strict models and authoritative state.
- `lib/providers/diorama_provider.dart`: lifecycle/actions/live-demo split, simulated fountain.
- `music_provider.dart`: reported audio/queue/completion/busy ordering.
- `lib/ui/tabs/music_tab.dart`: original restored layout, live History1/Xmas2, blocked-tap feedback.
- `control_tab.dart`: four tiles/no individual pumps. `home_tab.dart`: sensors/mode/logs. `flag_tab.dart`: explicit holds/unknown position.
- `lib/ui/screens/connect_screen.dart`, `main_layout.dart`: Wi-Fi/nav/tab exit/header.
- `lib/main.dart`: providers, MusicProvider bound using ChangeNotifierProxyProvider.
- Android manifest/network-security XML: local device HTTP.
- Pre-app-baseline setup also changed `android/local.properties`, `pubspec.yaml`/lockfile, vendored plugin Gradle files, intro screen/test. Original pre-setup ZIP: `C:/Users/josep/Downloads/dioramaapp-before-android-setup-20261103.zip`.

Read current records first: `docs/implementation/manual-flag-guard.md`, `docs/implementation/dancing-fountain.md`, `docs/implementation/wifi-app/audio-debug-2026-11-04.md`, `docs/wifi-api-v1.md`. Older specs/plans under `docs/superpowers/` are context; apply later overrides above.

## 10. Exact commands

### A. Run these next: read-only discovery/status

PowerShell. These do not start pumps, move flag, upload or reset boards.

```powershell
$masterRoot = 'C:/Users/josep/OneDrive/OneDriveFiles/Arduino/masterminiature'
$slaveRoot = 'C:/Users/josep/OneDrive/OneDriveFiles/Arduino/slaveminiature'
$appRoot = 'C:/Users/josep/Downloads/dioramaapp'
$arduinoCli = 'C:/Users/josep/AppData/Local/Programs/Arduino IDE/resources/app/lib/backend/resources/arduino-cli.exe'
$flutterPath = 'C:/Users/josep/development/flutter/bin/flutter.bat'
$adbPath = 'C:/Users/josep/AppData/Local/Android/Sdk/platform-tools/adb.exe'
$phoneId = 'H6WC4HGM7LGULNQO'
Set-Location -LiteralPath $masterRoot
foreach ($repoPath in @($masterRoot, $slaveRoot, $appRoot)) {
    Write-Output $repoPath
    git -C $repoPath status --short
    git -C $repoPath log -3 --oneline
}
[System.IO.Ports.SerialPort]::GetPortNames()
& $arduinoCli board list --format json
& $adbPath devices -l
& $adbPath -s $phoneId shell cmd wifi status | Select-String 'connected to|IP:'
```

If communication is needed and phone is on home Wi-Fi, reconnect to the known AP, allowing DHCP time:

```powershell
& $adbPath -s $phoneId shell cmd wifi connect-network ESP32_Master_Diorama wpa2 password123
Start-Sleep -Seconds 3
& $adbPath -s $phoneId shell cmd wifi status | Select-String 'connected to|IP:'
```

Phone shell lacked curl/wget. This working base64 + toybox nc pattern avoids PowerShell/ADB CRLF quoting corruption (which previously produced a misleading HTTP408):

```powershell
function Get-DioramaStatus {
    $deviceRequest = "GET /api/v1/status HTTP/1.0`r`nHost: 192.168.4.1`r`nConnection: close`r`n`r`n"
    $deviceEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($deviceRequest))
    $deviceRaw = (& $adbPath -s $phoneId shell "echo $deviceEncoded | base64 -d | toybox nc -w 3 192.168.4.1 80") -join "`n"
    $deviceBodyOffset = $deviceRaw.IndexOf('{')
    if ($deviceBodyOffset -lt 0) { throw 'No master JSON; check phone Wi-Fi and master power.' }
    $deviceResponse = $deviceRaw.Substring($deviceBodyOffset) | ConvertFrom-Json
    if ($deviceResponse.error) { throw $deviceResponse.error.code }
    if ($deviceResponse.apiVersion -ne 1) { throw 'Unexpected API version.' }
    return $deviceResponse
}
$deviceStatus = Get-DioramaStatus
$deviceStatus.audio | ConvertTo-Json -Depth 10
$deviceStatus.motor | ConvertTo-Json -Depth 6
$deviceStatus.slave | ConvertTo-Json -Depth 6
New-Item -ItemType Directory -Path (Join-Path $masterRoot '.build') -Force | Out-Null
$snapshotPath = Join-Path $masterRoot ('.build/handoff-status-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
$deviceStatus | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $snapshotPath -Encoding utf8
Write-Output $snapshotPath
```

**If audio error is present, this saved snapshot is the immediate next diagnostic artifact. Do not reset first.** Inspect diagnostics.detail/raw fields/startupReady/counters against current state/ready/lastError. Then read `master_audio.ino`, `audio_monitor.h`, `wifi_controller.h`, and `../libraries/DFRobotDFPlayerMini/DFRobotDFPlayerMini.cpp`.

### B. Tests/builds when changes justify them

Do not rerun every build merely to read this handoff.

```powershell
Set-Location -LiteralPath $masterRoot
python tests/run_tests.py
python tools/check_wifi_fixtures.py --app-root $appRoot
# Focused flag checks if working on that area:
python tests/run_tests.py test_mode_motor_guard.cpp test_controller.cpp test_wifi_controller.cpp test_motor.cpp
Set-Location -LiteralPath $appRoot
& $flutterPath analyze
& $flutterPath test
# Only when preparing a changed APK:
& $flutterPath build apk --debug --target-platform android-arm64
```

### C. Master build/upload only when needed

Latest source is already flashed. Re-identify master before uploading. **115200 is the proven upload speed.** An earlier921600 attempt lost USB mid-write; a later full verified upload recovered it. Serial Monitor can automatically reopen and reclaim COM13 after reconnect; close its monitor connection first. Do not close/discard unsaved IDE files.

```powershell
Set-Location -LiteralPath $masterRoot
& $arduinoCli compile --fqbn esp32:esp32:esp32 --jobs 4 --libraries ../libraries --build-path .build/esp32 .
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed; do not upload.' }
& $arduinoCli upload --fqbn esp32:esp32:esp32 --port COM13 --upload-property upload.speed=115200 --verify --input-dir .build/esp32 .
if ($LASTEXITCODE -ne 0) { throw 'Upload failed; do not claim installation.' }
```

To restore the already-verified latest guard bundle without rebuilding, after master/port identification:

```powershell
Set-Location -LiteralPath $masterRoot
Get-Content .build/manual-flag-guard/manifest.json
Get-FileHash -Algorithm SHA256 .build/manual-flag-guard/masterminiature.ino.bin
& $arduinoCli upload --fqbn esp32:esp32:esp32 --port COM13 --upload-property upload.speed=115200 --verify --input-dir .build/manual-flag-guard .
```

Full two-sketch compilation if shared protocol changes require it:

```powershell
Set-Location -LiteralPath $masterRoot
powershell -NoProfile -ExecutionPolicy Bypass -File tests/build.ps1
```

Do not reflash slave unnecessarily or undo user pins. Reconnect phone to AP after master restart if Android switched networks.

### D. APK install only after app changes

```powershell
Set-Location -LiteralPath $appRoot
& $adbPath -s $phoneId install -r build/app/outputs/flutter-apk/app-debug.apk
& $adbPath -s $phoneId shell am start -n com.example.dioramaapp/.MainActivity
```

Existing authorization includes corrected APK install/run on this phone. Android denied remote touch/wake with INJECT_EVENTS permission errors; install/launch/screenshots worked. Ask user to unlock/open a screen if needed instead of repeatedly trying denied input injection.

### E. Local bench scripts: actuate hardware, not default resume commands

Read scripts first and run only for deliberate hardware verification:

```powershell
Set-Location -LiteralPath $masterRoot
Get-Content .build/test_manual_flag_guard.ps1
Get-Content .build/test_live_fountain.ps1
# Changes Auto/Manual three times, restores initial mode:
powershell -NoProfile -ExecutionPolicy Bypass -File .build/test_manual_flag_guard.ps1
# Starts audio/pumps about11s, captures sequence, sends OFF in finally:
powershell -NoProfile -ExecutionPolicy Bypass -File .build/test_live_fountain.ps1
```

Ignored scripts may be absent in a fresh clone; they are not required to re-prove user-confirmed behavior. Do not send an unsolicited flag move toward an unknown endpoint.

### F. History/rollback

```powershell
git -C $masterRoot show 40abc79 --stat
git -C $masterRoot log --oneline --decorate -15
git -C $appRoot show bcb367c --stat
git -C $slaveRoot show 34ceedb --stat
```

For an intentional rollback, save future edits first, then use `git switch --detach before-wifi-integration` in the specific repo and rebuild/install/flash that baseline as appropriate. Preserve feature history. Return master/app via `git switch feature/wifi-app-integration`; slave uses `feature/miniature-functions`.

## 11. Full versioned file inventories

Inventories below include original feature work and later changes, not just the last fix. Pre-app-baseline Android setup files are separately described above. Generated binaries/logs are omitted.

### Master: baseline-before-features to 471a51f

```text
.gitignore
README.md
audio_monitor.h
combined_action.h
docs/bench-checklist.md
docs/implementation/dancing-fountain.md
docs/implementation/manual-flag-guard.md
docs/implementation/progress.md
docs/implementation/verification.md
docs/implementation/wifi-app/audio-debug-2026-11-04.md
docs/implementation/wifi-app/progress.md
docs/implementation/wifi-app/verification.md
docs/superpowers/plans/2026-11-03-miniature-functions.md
docs/superpowers/plans/2026-11-04-dancing-fountain.md
docs/superpowers/plans/2026-11-04-wifi-app-integration.md
docs/superpowers/specs/2026-11-03-miniature-functions-design.md
docs/superpowers/specs/2026-11-04-wifi-app-integration-design.md
docs/wifi-api-v1.md
docs/wifi-app-bench-checklist.md
feedback.h
master_api_controller.ino
master_audio.ino
master_buttons_rgb.ino
master_config.h
master_controller.h
master_controller.ino
master_espnow.ino
master_leds.ino
master_motor.ino
master_sensors.ino
master_wifi.ino
masterminiature.ino
miniature_protocol.h
motion_lease.h
reliable_link.h
tests/build.ps1
tests/fixtures/wifi_api/error_mode.json
tests/fixtures/wifi_api/request_flag_move.json
tests/fixtures/wifi_api/request_light_on.json
tests/fixtures/wifi_api/result_applied.json
tests/fixtures/wifi_api/result_failed.json
tests/fixtures/wifi_api/result_pending.json
tests/fixtures/wifi_api/status_audio_paused.json
tests/fixtures/wifi_api/status_auto.json
tests/fixtures/wifi_api/status_boot_changed.json
tests/fixtures/wifi_api/status_manual.json
tests/fixtures/wifi_api/status_slave_offline.json
tests/fixtures/wifi_api/status_sound_pulse.json
tests/run_tests.py
tests/test_audio.cpp
tests/test_audio_adapter.cpp
tests/test_color.cpp
tests/test_combined.cpp
tests/test_controller.cpp
tests/test_dancing_controller.cpp
tests/test_feedback.cpp
tests/test_link.cpp
tests/test_mode_motor_guard.cpp
tests/test_motion_lease.cpp
tests/test_motor.cpp
tests/test_protocol.cpp
tests/test_wifi_api.cpp
tests/test_wifi_controller.cpp
tests/test_wifi_status.cpp
tools/check_wifi_fixtures.py
tools/create_wifi_fixtures.py
web_bridge.h
wifi_api.h
wifi_controller.h
wifi_json.h
wifi_status.h
```

### Slave: baseline-before-features to 34ceedb

```text
.gitignore
README.md
feedback.h
miniature_protocol.h
reliable_link.h
slave_color.h
slave_config.h
slave_espnow.ino
slave_lcd.ino
slave_sensors.ino
slaveminiature.ino
```

### App: before-wifi-integration to 8ada1ff

```text
.gitignore
WIFI_INTEGRATION.md
analysis_options.yaml
android/app/src/main/AndroidManifest.xml
android/app/src/main/res/xml/network_security_config.xml
android/build/reports/problems/problems-report.html
lib/main.dart
lib/models/api_command.dart
lib/models/command_result.dart
lib/models/device_status.dart
lib/models/esp_state.dart
lib/models/music_track.dart
lib/providers/diorama_provider.dart
lib/providers/music_provider.dart
lib/services/connection_manager.dart
lib/services/flag_session.dart
lib/services/wifi_client.dart
lib/ui/screens/connect_screen.dart
lib/ui/screens/main_layout.dart
lib/ui/tabs/control_tab.dart
lib/ui/tabs/flag_tab.dart
lib/ui/tabs/home_tab.dart
lib/ui/tabs/music_tab.dart
lib/ui/widgets/control_tile.dart
lib/ui/widgets/diorama_svg.dart
lib/ui/widgets/flag_visual.dart
test/fixtures/wifi_api/error_mode.json
test/fixtures/wifi_api/request_flag_move.json
test/fixtures/wifi_api/request_light_on.json
test/fixtures/wifi_api/result_applied.json
test/fixtures/wifi_api/result_failed.json
test/fixtures/wifi_api/result_pending.json
test/fixtures/wifi_api/status_audio_paused.json
test/fixtures/wifi_api/status_auto.json
test/fixtures/wifi_api/status_boot_changed.json
test/fixtures/wifi_api/status_manual.json
test/fixtures/wifi_api/status_slave_offline.json
test/fixtures/wifi_api/status_sound_pulse.json
test/models/device_status_test.dart
test/providers/diorama_provider_test.dart
test/providers/music_provider_test.dart
test/services/connection_manager_test.dart
test/services/flag_session_test.dart
test/services/wifi_client_test.dart
test/widget_test.dart
test/widgets/flag_controls_test.dart
test/widgets/music_controls_test.dart
test/widgets/wifi_controls_test.dart
```

The app inventory includes removal of an accidentally tracked generated Android build report; it is not product source. These inventories predate CODEX_HANDOFF.md itself. No existing source was changed while preparing this handoff.
