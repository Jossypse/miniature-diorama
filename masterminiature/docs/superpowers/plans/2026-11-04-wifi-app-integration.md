# Android Wi-Fi Device Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for native execution or superpowers:subagent-driven-development for the selected delegated execution method. Execute task by task and track the checkboxes.

**Goal:** Connect the Flutter Android app to confirmed miniature state and controls over Wi-Fi, including bounded app flag movement.

**Architecture:** Extend the master's existing HTTP worker/main-controller queue with a versioned JSON API, bounded command results and coherent status snapshots. Flutter uses typed API models, single-flight foreground polling and explicit commands; firmware remains the authority. Existing master/slave ESP-NOW packet format remains compatible.

**Tech Stack:** Flutter 3.47.9 / Dart 3.13.7, package:http, Provider, Android SDK36/NDK28.2.13676358, Espressif Arduino core3.3.12, WebServer, ArduinoJson (installed library), Adafruit_NeoPixel, DFRobotDFPlayerMini, portable C++ host tests with MSVC.

**Spec:** `../specs/2026-11-04-wifi-app-integration-design.md`, approved 2026-11-04.

**Locations:** firmware root is `C:/Users/josep/OneDrive/OneDriveFiles/Arduino/masterminiature`; app root is `C:/Users/josep/Downloads/dioramaapp`; slave is the sibling `slaveminiature` folder. App paths below are explicitly prefixed `APP/`.

## Global Constraints

- Wi-Fi first: phone joins ESP32_Master_Diorama (password password123); master URL http://192.168.4.1.
- Preserve the user's slave pin assignments IR=4 and SOUND=5; other wiring unchanged.
- Poll every 1000 ms; HTTP timeout 2000 ms; at most one status request in flight.
- Two consecutive transport/protocol failures mark master offline; pause/detach stops polling and motion renewals.
- Status polling drives existing LCD app freshness (5000 ms); master/slave heartbeat behavior remains.
- Request IDs: 1–48 ASCII letters/digits/underscore/hyphen; JSON request bodies capped at 512 bytes.
- Result table: 16 records; never evict pending records; reclaim oldest terminal record if necessary.
- 202 means queued, 200 means cached terminal duplicate; 400 malformed/unknown, 409 mode/boot/conflicting ID, 422 unsupported arguments, 503 unavailable/full queue; unknown result ID returns 404.
- App setters are explicit and never automatically replayed after timeout/reconnect/reboot.
- Motor renewals every 200 ms, expiry 1000 ms, continuous app gesture cap 5000 ms; joystick priority.
- Sound indicator uses the 2000 ms hold window and a report sequence, not physical noise counts.
- Initial configurable SD tracks 1 and 2; live phone playback, Bluetooth, automatic narration and measured flag percentage unavailable.
- Preserve browser controls, physical controls, diagnostics, demo mode and the app's visual identity.
- Prepare firmware/APK and record actual checks; connected hardware is required for physical verification.

## Review Focus

1. A request accepted before a physical mode change must be revalidated in the main controller; pending must not become false success (Tasks2/3/8).
2. Delayed renewals after release/expiry or after joystick takeover must never revive app movement, including across timer wrap (Tasks4/7).
3. A 200 ms sound report must remain visible to a 1000 ms status poll without inventing continuous raw detection (Tasks3/6).
4. Timed-out/reordered responses after demo/lifecycle/boot changes must not overwrite current state or replay actuators (Tasks6/7).
5. Audio completion/pause/error and independent relay commands must not advance a queue twice or leave a combined pump action active (Tasks5/9).

## Task 1: Checkpoints, wire fixtures and repeatable verification

**Files:** create `docs/wifi-api-v1.md`, `tests/fixtures/wifi_api/`, `tools/check_wifi_fixtures.py`, `APP/test/fixtures/wifi_api/`; update app `.gitignore` only for actual generated build artifacts if needed. Add a short implementation ledger under `docs/implementation/wifi-app/`.

**Interfaces produced:** shared API-v1 fixture vocabulary below; copies are self-contained in each repository. No production behavior in this task.

- [ ] Confirm branch/status in all folders. Master already uses `feature/wifi-app-integration`. Initialize APP's Git repository after checking ignore rules and baseline its current source, local vendor patch and intro fix. Exclude SDKs/builds/logs/archives. Preserve the uncommitted slave pin swap; checkpoint it separately, with an accurate message, before creating `before-wifi-integration` tags. Do not reset current working files or move the user to a different Arduino sketch folder.
- [ ] Record tools/baseline host-test results and the known `APP/test/widget_test.dart` failure (`MyApp` no longer exists). That test is replaced in Task8; this known failure is not permission to ignore new failures.
- [ ] Write literal fixtures `status_manual.json`, `status_auto.json`, `status_slave_offline.json`, `status_sound_pulse.json`, `status_audio_paused.json`, `status_boot_changed.json`, `request_light_on.json`, `request_flag_move.json`, `result_pending.json`, `result_applied.json`, `result_failed.json` and `error_mode.json`. Define all fields/types/null semantics in wifi-api-v1.md before writing either serializer/parser.
- [ ] Copy fixtures to APP; `python tools/check_wifi_fixtures.py --app-root C:/Users/josep/Downloads/dioramaapp` must report byte-identical fixture sets. This checks distribution only; behavior tests in later tasks must parse/produce actual data.
- [ ] Commit the contract/checkpoint work locally and record baseline hashes in the ledger.

### Wire vocabulary pinned by this plan

Status keys: `apiVersion:1`, `bootId` (8 lowercase hex digits), `revision`, `uptimeMs`, `mode` (`automatic|manual`), `app:{online}`, `slave:{connected,fresh,ageMs}`, `sensors:{fresh,color,ir,joyY,sound:{sequence,lastTriggerAgeMs,detected}}`, `outputs:{fountain:{enabled,color},building:{enabled},rgb:{enabled,effect},relays:{known,desired,confirmed,pending}}`, `audio:{ready,requested,state,trackId,volumePercent,completionSequence,lastError}`, `combined:{state}`, `motor:{direction,owner,leaseRemainingMs,positionPercent}`, `capabilities` and `logs`.

Colors use `NONE|RED|GREEN|BLUE|YELLOW|WHITE`. Stale sensor values are null; stale sound detected is null. Sound sequence counts received reports. Relay confirmed is null when unknown; desired/confirmed masks otherwise use bits1/2. Motor direction is `stopped|raising|lowering`, owner `none|joystick|app`; positionPercent is null. Logs contain at most eight `{sequence,code,message}` entries. Capabilities explicitly report supported flags and track IDs/titles. Audio state is `stopped|starting|playing|paused|error`; trackId/lastError may be null. Combined state is `off|starting|active|failed`.

Capability keys are booleans `wifi`, `bluetooth`, `flagApp`, `flagPosition`, `audioPause`, `audioVolume`, `autoNarration`, `phonePlayback`, plus `tracks:[{id:int,title:string}]`. Initial values are true/false/true/false/true/true/false/false respectively, with tracks1/2 titled Track 1/Track 2.

Request envelope: `{id,bootId,action,args}`. Result envelope: `{apiVersion,bootId,id,status,reason,acceptedAtMs,finishedAtMs}` with status `pending|applied|failed`, nullable reason/finishedAtMs. Errors use `{apiVersion,error:{code,message}}`. Boolean/integer fields require the correct JSON type; never coerce strings such as `"false"` or negative/overflowing numbers.

Arguments: mode.set `{automatic:bool}`; light.set `{target:fountain|building|rgb,enabled:bool}`; relay.set `{relay:1|2,enabled:bool}`; combined.set `{enabled:bool}`; audio.play `{trackId:int}`; audio.pause/resume/stop `{}`; audio.volume `{percent:0..100}`; flag.move `{leaseId,sequence:uint32,direction:raising|lowering}`; flag.stop `{leaseId,sequence:uint32}`. Lease IDs use the same character/length rules as request IDs. Reject missing required or unknown arguments; an empty object is valid for the zero-argument audio actions. Hardware emergency stop is internal and must not be confused with an old lease's normal stop request.

Machine reason codes: `BAD_REQUEST`, `INVALID_ID`, `BOOT_MISMATCH`, `MODE_REJECTED`, `INVALID_ARGUMENT`, `UNSUPPORTED`, `SLAVE_OFFLINE`, `AUDIO_UNAVAILABLE`, `QUEUE_FULL`, `SUPERSEDED`, `LINK_LOST`, `AUDIO_TIMEOUT`, `COMMAND_TIMEOUT`, `MOTION_EXPIRED`, `JOYSTICK_OVERRIDE`, `MOTION_LIMIT`, `UNKNOWN_ID`, `INTERNAL`. An applied result has reason null. Log `code` is the numeric existing firmware Event value; UI displays the supplied bounded message. Unknown future reason/log codes must not crash the app.

## Task 2: Bounded commands and HTTP admission

**Files:** create `wifi_api.h`, `wifi_json.h`, `wifi_api.ino`, `tests/test_wifi_api.cpp`; modify `web_bridge.h`, `master_wifi.ino`, `tests/run_tests.py`.

**Interfaces:** `bool decodeApiCommand(const char* json,size_t length,ApiCommand& out,ApiError& error)`; `Admission CommandRegistry::admit(const ApiCommand&,uint32_t now)`; `bool CommandRegistry::lookup(const char* id,CommandResult& out) const`; `bool CommandRegistry::finish(const char* id,CommandStatus,Reason,uint32_t now)`; `ApiReply handleApiRequest(const ApiHttpRequest&)`. Typed commands contain fixed-width fields and bounded IDs. Canonical equality compares normalized command fields, not raw JSON whitespace. ApiReply carries HTTP code and bounded JSON. Registry access from HTTP/main is synchronized by adapters, not hidden inside the portable class; lookup copies a record while locked, so socket serialization never retains a mutable table pointer.

Define all common data-only types in wifi_api.h in this task, including ApiCommand, ApiError, ApiReply, CommandResult, DeviceSnapshot and AudioState, so later tasks share actual interfaces. Capture/serialization is Task3; audio operations/completion semantics are Task5. The new header does not change the ESP-NOW Packet ABI.

- [ ] Write failing host tests for valid fixture decoding, 512/513-byte boundary, malformed/nested JSON, invalid IDs/types/boot IDs, argument ranges, unknown commands and semantic duplicates with different JSON whitespace. Run `python tests/run_tests.py test_wifi_api.cpp` and observe failure before implementation.
- [ ] Implement the portable decoder/registry using installed ArduinoJson with bounded nesting; add its include directory to host compilation. Test all16 pending records reject a17th, oldest terminal eviction, no pending eviction, duplicate same-content no re-execution, changed-content409 and missing-result404. Failed queue admission must leave no permanently pending record.
- [ ] Wire POST `/api/v1/commands` and GET `/api/v1/commands/{id}` through the existing HTTP worker. Allocate/copy payloads off large stack frames; no socket operation holds controller/registry mutexes. Main queue transports typed command plus stable record identity; no direct HTTP actuator writes.
- [ ] Adapt legacy web actions to the same executor path without requiring mobile IDs. Preserve existing browser routes and status polling. Add host tests through handleApiRequest for response codes and queued-vs-applied semantics, not just parser methods.
- [ ] Run all current host tests, check body/error response bounds, commit Task2 and record results.

## Task 3: Main-controller execution, status and confirmations

**Files:** create `wifi_controller.h`, `master_api_controller.ino`, `tests/test_wifi_controller.cpp`; modify `master_controller.h/.ino`, `master_espnow.ino`, `master_wifi.ino`, `master_buttons_rgb.ino`, `masterminiature.ino`, `master_config.h`.

**Interfaces:** `ExecutionOutcome executeCommand(const ApiCommand&,uint32_t now)`; `void serviceApiResults(uint32_t now)`; `DeviceSnapshot captureDeviceSnapshot(uint32_t now)`; `String serializeStatus(const DeviceSnapshot&)`. `SensorHistory::observe(const Packet&,uint32_t receivedAt)` retains trigger sequence/last time before readings.sound is cleared. DeviceSnapshot is portable data; serializer output uses Task1's fixture schema. `Controller::setMode(bool,uint32_t)` becomes a no-op when already in that mode.

- [ ] Write failing tests: explicit same-mode command does not clear manual outputs, opposite mode clears them, queued light rejected after physical mode change, physical outputs reconcile in a snapshot, stale sensors serialize null, local outputs stay known when slave offline, short sound report remains in sequence/history until a later poll, and millis wrap preserves age calculations.
- [ ] Implement a boot ID stable for the master boot, revision updates for semantic changes, and coherent bounded snapshots. Add GET `/api/v1/status`; valid status reads refresh app polling presence. Legacy `/status` remains browser compatible. Do not reset sound history on each control loop.
- [ ] Track each asynchronous relay result against its ESP-NOW command sequence and each audio/combined operation against its generation. A new conflicting operation marks older pending records failed/superseded. Ack mismatch, reconnect or watchdog failure cannot mark an unrelated command applied. Keep registry pending until the actual completion criterion is reached.
- [ ] Test initial/duplicate/applied/failed result fixtures, delayed old acknowledgments, physical-button supersession, full queue handling and missing/evicted result IDs. Keep current slave packet unchanged; run shared-header checks.
- [ ] Run `python tests/run_tests.py` and provisional master compilation, then commit Task3.

## Task 4: Bounded app motor leases and joystick arbitration

**Files:** create `motion_lease.h`, `tests/test_motion_lease.cpp`; modify `wifi_controller.h`, `master_api_controller.ino`, `master_controller.ino`, `master_motor.ino`, `master_config.h`.

**Interfaces:** `MotionDecision MotionLease::move(const char* leaseId,uint32_t sequence,int8_t direction,uint32_t now)`; `MotionDecision MotionLease::stop(const char* leaseId,uint32_t sequence,uint32_t now)`; `void MotionLease::revoke(uint32_t now)`; `MotorDecision arbitrateMotor(const SensorState&,bool automatic,uint32_t now)`. Keep four most-recent ended leases as tombstones, with monotonic sequence checking. Never renew an ended lease; app creates a fresh ID for each deliberate gesture.

- [ ] Write failing tests for manual/freshness prerequisites, renewal at200ms, exact1000ms expiry, exact5000ms cap despite renewals, duplicate/out-of-order renewal, stop arriving before delayed move, expired/revoked lease replay, competing owners, unrelated old stop, timer rollover and lease-cache bounds.
- [ ] Implement arbitration: deflected joystick revokes app motion and takes priority; centering does not restore an old lease. Mode changes/slave loss/reboot stop and revoke app motion. Apply logical direction through existing MOTOR_REVERSED mapping and zero-PWM-before-direction-change adapter.
- [ ] Test end-to-end queued API lease requests including late HTTP actions: stop preempts queued renewals for its lease, an old press cannot revive motion after5s, and output/source in status matches the winner. Retain existing manual joystick behavior when no app lease is active.
- [ ] Run all host tests including actual motor adapter, compile master and commit Task4. No measured height/endpoints may be reported.

## Task 5: Device audio, explicit combined action and completion state

**Files:** modify `master_audio.ino`, `audio_monitor.h`, `combined_action.h`, `master_api_controller.ino`, `master_config.h`; extend `tests/test_audio.cpp`, `tests/test_combined.cpp`, `tests/test_wifi_controller.cpp`.

**Interfaces:** `bool requestAudioPlay(uint16_t trackId)`; `bool requestAudioPause()`; `bool requestAudioResume()`; `void requestAudioStop()`; `bool requestAudioVolume(uint8_t percent)`; `bool requestCombined(bool enabled,uint32_t now)`; `AudioState captureAudioState()`. State contains operation generation and completion sequence; config declares tracks1/2. Map percent to module volume with nearest-integer `(percent*30+50)/100`.

- [ ] Write failing tests for volume0/50/100 mapping to0/15/30, unavailable/unsupported tracks, duplicate play ID not restarting, explicit combined on/off idempotency, paused verification not timing out, resume re-verification deadline1000ms, natural completion exactly once, and stale finish/ack/error after supersession.
- [ ] Implement nonblocking play/pause/resume/stop/volume via existing DFPlayer runtime mechanism. Pause first preserves track state; audio errors/removed card/deadline fail pending commands. A pause of combined playback stops its pump while preserving the paused standalone track; resume does not restart the combined pump automatically. Route physical Button5/browser operations through the same state owner.
- [ ] Test independent relay2 does not cancel combined, independent relay1/audio overrides do cancel it, stopping combined waits for pump OFF confirmation before returning applied, and failed OFF/peer loss reports unknown/failure instead of confirmed success.
- [ ] Keep queue policy on the app; firmware publishes a completion sequence and never fabricates playback time or SD titles. Run host suite/master build and commit Task5.

## Task 6: Flutter typed models and HTTP transport

**Files:** create `APP/lib/models/device_status.dart`, `api_command.dart`, `command_result.dart`, `APP/test/services/wifi_client_test.dart`, `APP/test/models/device_status_test.dart`; modify `APP/lib/services/wifi_client.dart`, `core/constants.dart`.

**Interfaces:** `DeviceStatus.fromJson(Map<String,dynamic>)`; `CommandResult.fromJson(Map<String,dynamic>)`; `WifiClient({http.Client? client,Uri? baseUri})`; `Future<DeviceStatus> fetchStatus()`; `Future<CommandResult> submit(ApiCommand command)`; `Future<CommandResult> fetchResult(String requestId)`. ApiCommand serializes the exact Task1 envelope with numeric/boolean values, not string commands. Define `LightTarget` and `FlagDirection` enums in api_command.dart and `ActionOutcome` in command_result.dart (nullable deviceResult, unconfirmed boolean, optional failure reason). ApiException includes HTTP status, machine reason and readable message.

- [ ] Write failing fixture tests for normal/stale/offline/paused/boot-changed status, unknown capability, invalid/missing/wrong-type required fields, API version mismatch, null sensor/relay/position fields and sound report sequence. Reject malformed data without overwriting previous good state.
- [ ] Use package:http/testing.dart MockClient to exercise real WifiClient requests/decoding: correct method/path/body, URL-safe request ID,200/202 distinction,400/409/422/503/404, invalid JSON and2000ms timeout. Assert no automatic POST retries and no fabricated state after acceptance.
- [ ] Implement typed models and transport, centralize base URL, dispose owned clients. Unknown optional extra JSON fields may be ignored for compatible API1, but required fields/types/version cannot be silently defaulted to online/success.
- [ ] Run `flutter test --no-pub test/services/wifi_client_test.dart test/models/device_status_test.dart` and `flutter analyze --no-pub lib`; commit Task6.

## Task 7: Flutter lifecycle, state reconciliation and held motion

**Files:** modify `APP/lib/services/connection_manager.dart`, `providers/diorama_provider.dart`, `models/esp_state.dart`; create `APP/lib/services/flag_session.dart`, `APP/test/providers/diorama_provider_test.dart`, `APP/test/services/connection_manager_test.dart`, `flag_session_test.dart`.

**Interfaces:** `ConnectionManager(EspState state,{WifiClient? client})`; `Future<void> ConnectionManager.connectWifi()`; `void setForeground(bool active)`; `Future<void> refresh()`; `Future<ActionOutcome> execute(ApiCommand)`; `Future<void> disconnect()`; `void EspState.applyDeviceStatus(DeviceStatus)`; `Future<void> DioramaProvider.setAppMode(bool automatic)`; `Future<ActionOutcome> setLight(LightTarget target,bool enabled)`, `setRelay(int relay,bool enabled)`, `setCombined(bool enabled)`; `FlagSession.start(FlagDirection)`, `stop()` and `dispose()`.

- [ ] Write failing async/fake-time tests for1000ms polling with one request in flight,2000ms request timeout, two failures offline, read-only recovery probes, first failure marking displayed data stale and suspending motion renewals, explicit connect single-flight, disposal and generation guards after demo/transport/boot changes.
- [ ] Implement shared authoritative state: remove live applyCommand optimism and separate provider mode flag; successful status refresh is the only source of actual mode/output values. Pending/unconfirmed actions remain distinct. Failed commands refresh status and show errors. Old replies cannot change the current session.
- [ ] Follow202 results using read-only polling every250ms for up to2500ms; then mark unconfirmed and refresh status, without replaying POST. A404 result also becomes unconfirmed. Cache/deduplicate in-flight UI operations and serialize conflicting actuator requests. Generate bounded random session/request IDs; maintain separate per-motion-lease sequence.
- [ ] Implement foreground observer integration: pause/detach/disconnect/navigation/dispose immediately cancel renewals, enqueue best-effort lease stop and invalidate old completions. Status refresh on resume must finish before controls/leases re-enable. Renew every200ms without building a backlog; only one renewal request in flight, stop has priority, no reuse after expiry/5s cap.
- [ ] Test physical mode/output reconciliation, slave offline blocking only remote relays/motor, sound counter update between polls, same-boot state revision, boot restart and no automatic command/queue replay. Run targeted Flutter tests/analyzer and commit Task7.

## Task 8: Wire existing controls, connection and flag screens

**Files:** modify `APP/lib/ui/screens/connect_screen.dart`, `main_layout.dart`, `ui/tabs/home_tab.dart`, `control_tab.dart`, `flag_tab.dart`, `ui/widgets/diorama_svg.dart`; update AndroidManifest.xml and create `APP/android/app/src/main/res/xml/network_security_config.xml`. Replace `APP/test/widget_test.dart`; add `wifi_controls_test.dart`, `flag_controls_test.dart`.

**Interfaces:** UI uses Task7 typed provider methods, lifecycle notifications, ActionOutcome and confirmed DeviceStatus. MainLayout reports selected flag-tab ownership to FlagSession; it cannot rely on dispose alone because IndexedStack keeps hidden tabs mounted.

- [ ] Write failing widget tests: connecting uses API status; manual lights disabled in automatic mode; accepted pending is not ON; physical changes update tiles/mode; fountain strip and pump1 are distinct; combined uses one action; offline values show unknown; stale sensors do not read clear/quiet; unsupported Bluetooth/narration/phone playback unavailable.
- [ ] Retain current colors/layout identity and connect Home sensor tiles, real recent ActivityLog, connection header and mode buttons. Add separately labeled pump1/pump2 controls; name Fountain lights clearly. Use task results for feedback. Use the existing Impeccable scoped native workflow when editing UI, with one inspection pass and one bounded confirmation.
- [ ] Replace fabricated real-device flag percent with unknown position and movement direction on both Home and Flag screens. Test pointer up/cancel, screen/tab exit, lifecycle pause and competing gestures all stop the owned lease. Demo visuals may still use simulated position, explicitly labeled demo.
- [ ] Configure local HTTP for the device using Android network security configuration; verify on the real phone AP. Replace stale MyApp counter test with actual DioramaApp startup/connect smoke coverage, retaining intro_layout_test.dart. Run the entire Flutter test suite and analyzer; all existing/new failures must be accounted for, not hidden by excluding files.
- [ ] Build debug APK, inspect changed screens at phone size when device/emulator is available, fix material interaction/layout regressions in one pass, commit Task8.

## Task 9: Music state, queue and supported device playback

**Files:** modify `APP/lib/providers/music_provider.dart`, `models/music_track.dart`, `ui/tabs/music_tab.dart`, `core/constants.dart`; create `APP/test/providers/music_provider_test.dart`, `APP/test/widgets/music_controls_test.dart`.

**Interfaces:** `void MusicProvider.applyDeviceAudio(AudioState audio,String bootId,bool foreground)` reconciles confirmed playback; `Future<ActionOutcome> playTrackId(int)`, `pause()`, `resume()`, `stop()`, `setVolume(int percent)` dispatch through Task7's provider. Track metadata is taken from DeviceStatus.capabilities; queue IDs must exist in that catalog. User track queue advances once for a new completion sequence only while foregrounded, connected and still in the same boot/session.

- [ ] Write failing tests for starting-vs-playing, confirmed pause/resume/error/volume, unsupported IDs, queued transition only after a new completion sequence, duplicate completion, first state after reconnect, boot change, backgrounded completion and command failure. No device completion may be inferred from the old local duration timer.
- [ ] Replace live timer authority with firmware state. Never install command callbacks inside widget build or send duplicate play requests from UI and provider. Scope existing simulated timer behavior to demo mode only. Explicitly disable live phone playback/narration and unknown tracks according to capabilities.
- [ ] Wire controls/queue/volume to asynchronous ActionOutcome and shared audio/combined states. Display unknown elapsed/duration values honestly. Replace the missing vinyl_texture.png reference with the existing code-rendered vinyl widget or shipped fallback, retaining the current interface identity.
- [ ] Run all Flutter tests/analyzer and build APK; check the Music tab and combined control with API fixtures, then commit Task9.

## Task 10: Whole-system verification, review, artifacts and rollback

**Files:** create `docs/wifi-app-bench-checklist.md`, `docs/implementation/wifi-app/verification.md`, `APP/WIFI_INTEGRATION.md`; update root README/API docs and branch/tag record.

- [ ] Self-review every approved requirement against tasks and run fixture-copy check, full `python tests/run_tests.py`, both firmware builds via `powershell -File tests/build.ps1`, `flutter analyze`, full `flutter test`, and `flutter build apk --debug --target-platform android-arm64`. Use the installed explicit tool paths if the current shell has stale PATH. Read full failures and record actual command/exit results. No success claims from a partial suite.
- [ ] Request one fresh independent whole-change review across firmware/Flutter, using the approved spec, baseline hashes and fixture contract. Reproduce material findings with failing tests, fix, rerun the affected/full checks as justified. No automatic push or merge; retain local feature history and checkpoints.
- [ ] Prepare firmware image and APK with source commit IDs/API version. Install the reviewed APK under the existing phone authorization when USB is available; coordinate matching master firmware upload and physical checks with connected hardware. Slave should not need a protocol update; verify its compatibility/pins rather than reflashing needlessly.
- [ ] Execute/record bench checks: phone joins AP without Internet; master reachable with slave online/offline; every app/manual/auto control; physical button updates; short sound pulse; separate pumps and combined cancellation; two SD tracks/pause/volume/completion; app flag release/background/USB-independent Wi-Fi loss; joystick takeover/5s cap; board restart/old request rejection; slow client; LCD app5s timeout. Mark unavailable checks pending explicitly.
- [ ] Provide API docs, known hardware limits (unknown flag position/no endpoint detection), rollback instructions using `before-wifi-integration`, local commit IDs, verified artifacts and any material test/device limitations. Update ledger/task checkboxes only for work actually completed.

## Commands and handoff

Firmware test command: `python tests/run_tests.py` from firmware root. Installed Arduino CLI: `C:/Users/josep/AppData/Local/Programs/Arduino IDE/resources/app/lib/backend/resources/arduino-cli.exe`. Firmware build target remains provisional `esp32:esp32:esp32`, core3.3.12.

Flutter command: `C:/Users/josep/development/flutter/bin/flutter.bat`, run from APP root. Project setup/build compatibility is recorded in APP/ANDROID_SETUP.md. Physical Android device last used: H6WC4HGM7LGULNQO; verify connection rather than assuming it is present.

Recommended execution: native, in sequence, followed by one independent whole-change review. Most tasks share the API/state/controller interfaces; parallel implementation would add merge and contract coordination. Subagent-driven execution is an available alternative if the user wants a review gate per task.

## Execution status (2026-11-04)

- [x] Tasks1-5 implemented: local checkpoints/fixtures, API/controller, status, bounded motion and audio adapters.
- [x] Tasks6-9 implemented: typed Flutter transport, authoritative lifecycle state, existing screens, device music and separate demo simulation.
- [x] Task10 software suites and independent review/fix pass: host12/12, Flutter26/26, analyzer clean, APK built and installed.
- [x] Initial master/slave compilation passed; final build and manifest recorded in docs/implementation/wifi-app/verification.md.
- [ ] Physical API/load/SD/motor/LCD bench checklist: requires connected ESP32 hardware. No ESP32 USB device is present; COM9/10 are Bluetooth virtual ports.

Detailed per-task evidence and final rulings are in docs/implementation/wifi-app/progress.md. Physical requirements remain pending rather than marked complete based on software tests.
