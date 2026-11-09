# Android Wi-Fi integration design

Status: approved by user on 2026-11-04, including the proposed defaults below.

## Purpose and approach

Connect the existing Flutter Android app to the miniature's actual outputs,
sensor readings and physical controls. The phone joins ESP32_Master_Diorama
(password password123) and communicates with the master at http://192.168.4.1.
Master/slave ESP-NOW remains the sensor/relay transport.

Approaches considered:
- Wi-Fi first: extend the existing HTTP controller and adapt Flutter. Selected by user.
- Wi-Fi plus Bluetooth: requires a second firmware transport, command arbitration
  and additional acceptance tests. Deferred from this release.

Success means the app reflects real device state, including physical button
changes, and never shows a queued or failed action as confirmed success.
Retain the existing visual identity and browser control page.

## Baseline and scope

Before implementation, establish a local Git baseline for the Flutter app,
including its Android build compatibility changes, and checkpoint firmware.
Preserve the user's uncommitted slave pin swap: IR=4 and SOUND=5. Do not reset it.
Other wiring remains master buttons 13/12/14/27/26, fountain33, building25,
RGB19/21/22 and motor18/5/4. Record baseline tags in all affected repositories.

Implement Wi-Fi connection, live status, modes, lighting, separate pump controls,
combined track1/pump1 action, device audio and bounded app flag movement.
Bluetooth, cloud access, phone audio streaming, automatic narration policy and
new position/limit-switch hardware are outside this release. Unsupported hardware
capabilities must be visibly unavailable, not simulated during real operation.
Demo mode remains available as an explicitly separate local simulation.

## Device HTTP contract

Add a versioned JSON API alongside current browser routes:
- GET /api/v1/status: connection check and coherent current state.
- POST /api/v1/commands: validated typed command with a unique request ID and
  expected master boot/session ID from the latest status.
- GET /api/v1/commands/{id}: recent execution result for a submitted request.

Status includes API version, boot ID, state revision, uptime, slave connection,
telemetry age/freshness, app freshness, capabilities, outputs, sensors, audio,
motor state and the bounded recent event log.

Sensor values become null/unknown when stale. Expose normalized IR detection,
detected color, joystick Y, and a sound report sequence plus time since last
trigger. Sound reports represent received telemetry triggers, not a calibrated
count of individual noises. Use the last-trigger timestamp/sequence rather than
the one-loop sound boolean, which the current controller consumes immediately.
The app can display a recent sound indication for the same 2000 ms hold window.

Output state includes fountain enabled/color, building enabled, RGB enabled/cycle,
relay desired/confirmed/pending/known, combined off/starting/active/failed, and
motor stopped/raising/lowering plus control owner. No physical flow, LED current,
audible sound or flag-position measurement is implied by a commanded output.

Audio reports ready, requested/starting/playing/paused/stopped/error, selected
track ID, configured volume and a monotonic completion sequence. Actual track
duration/elapsed position is unknown unless separately measured; stop using the
app's fabricated timer as device playback authority.

HTTP handling stays in its worker task. Actions are queued to the main controller;
only the main task mutates modes/peripherals. JSON snapshots are bounded and
copied without holding a mutex during socket reads/writes. Any larger response
buffers must avoid overflowing the existing HTTP task's stack.

### Commands and results

Typed actions: mode.set, light.set, relay.set, combined.set, audio.play,
audio.pause, audio.resume, audio.stop, audio.volume, flag.move and flag.stop.
Setters carry explicit desired values; mobile controls never retry a toggle.
mode.set automatic/manual is idempotent: setting the already-active mode must
not clear outputs or restart movement. Existing browser/physical toggle controls
continue to use the same central mode controller for real transitions.

Request IDs use 1–48 ASCII letters/digits/underscore/hyphen; JSON request bodies
are capped at 512 bytes. HTTP 202 means queued; HTTP 200 returns a cached completed
result for a duplicate request. Use 400 for malformed/unknown commands, 409 for
wrong mode/boot ID or conflicting duplicate content, 422 for unsupported arguments,
and 503 for unavailable hardware or a full queue. Revalidate conditions when the
main task executes the request because state can change after HTTP admission.

Store a bounded recent result table (16 records), keeping pending records until
terminal. Reusing a cached ID with the same payload returns the existing result
without repeating its side effects. Execution results are pending/applied/failed
with a bounded reason code. If full with pending records, reject admission; reclaim
the oldest terminal record otherwise. Missing/evicted IDs return 404, never success.
This is recent deduplication, not an unlimited transaction history.

The app sends actuator commands once and does not automatically replay them after
timeouts, connection loss or reboot. After an ambiguous timeout it refreshes state
and shows unconfirmed status. For relay/combined activation, applied means matching
slave acknowledgement (plus verified playing state for combined activation).
For lights/mode/volume it means the controller accepted/applied the requested
setting, not electrical measurement. Audio play/resume stays pending until the
existing asynchronous playing-state check succeeds; its one-second timeout fails
the command. Conflicting pending relay changes are marked superseded/failed
rather than silently presenting earlier requests as successful.

## Control behavior

Manual mode: fountain strip is blue, building strip is yellow, RGB cycles colors.
Automatic mode retains color/IR/sound rules. Reject manual lighting commands in
automatic mode; the app must explicitly set manual mode and await confirmation.
Physical mode changes immediately become authoritative in app status.

Keep the Fountain lighting tile for the NeoPixel strip. Label it clearly and add
separate pump1/pump2 controls. Sound + Fountain uses one combined.set action for
track1 and pump1, not two unrelated audio/lighting requests. Its state is separate
from standalone audio playing. Retain current combined cancellation on audio
failure, track completion, peer loss and independent audio/relay1 override;
relay2 remains independent. On lost app polling, independent pumps follow existing
master/slave watchdog behavior; closing the app alone does not silently switch
off a pump started by a physical button or browser.

Provide device volume 0–100 mapped to DFPlayer 0–30, play, pause, resume and stop.
Pause suspends the playing-state verification deadline; resume restarts it.
Pausing/stopping or independently changing a combined track cancels its pump action.
Playback errors and natural completion update the shared state and completion
sequence. Queue advancement uses a newly observed completion sequence exactly once,
not the app's guessed duration; reconnect never automatically advances/restarts.
Queued playback is app-local and stops advancing while the app is backgrounded.
Initial supported SD tracks are configurable IDs 1 and 2, with neutral Track 1/2
labels until actual file titles are verified. Additional tracks require files
and configuration. Disable unknown tracks, auto narration and unsupported phone
playback in live device mode; retain demo behavior only in demo mode.

### App and joystick motor arbitration (proposed defaults)

App flag controls are hold-to-run in manual mode, with fresh slave telemetry.
Start a new unique motion lease per gesture; renew every 200 ms while held.
The firmware lease expires after 1000 ms without an accepted renewal. Release,
pointer cancellation, leaving the flag tab, backgrounding, disposal or explicit
disconnect sends stop and immediately stops renewals. No motion replay on reconnect.

Joystick outside its center deadband has priority: revoke the app lease and
tombstone it, use joystick direction, then require a fresh app press after joystick
recenters. Mode changes, slave loss and master reboot revoke app motion. A stopped,
revoked or expired lease cannot be revived by a delayed renewal. Track monotonically
increasing sequence numbers within each lease and retain a bounded cache of recent
ended leases. Reject competing app leases while one is active; a stop for an old
lease must not stop an unrelated newer lease. A global emergency stop may stop all.

Limit each continuous app gesture to 5000 ms, even with renewals; another deliberate
press is required to continue. This is a proposed configurable travel bound, not
endpoint sensing. No automatic endpoint detection exists on the hardware. Real
flag height must display unknown rather than a fake percentage; demonstrate
direction with the existing flag visual without implying measured position.

## Flutter connection/state changes

Replace ping/CSV/string-command assumptions in WifiClient with the versioned API
and typed models. Inject the HTTP client/base URL so transport tests use fixtures.
Use one shared state model for mode/output/device status; remove local optimistic
state mutations for live commands. Pending indicators are separate from actual
confirmed output states. Refresh after commands and reconcile physical controls.

Poll every 1000 ms while foregrounded, with a 2000 ms request timeout and at most
one in flight. Stop polling/renewals on pause/detach; on resume fetch fresh state
before enabling commands. After two consecutive transport/protocol failures mark
the master offline, clear command eligibility, retain previous values as stale,
and keep read-only reconnect probes running. Only a valid API-v1 response restores
connection. Reachable master with offline slave is a distinct state: local lights
and audio may remain controllable, while pumps and motor are unavailable.

Ignore old async replies after transport/demo/session changes or disposal.
Boot ID changes invalidate pending requests and motion; require fresh user actions.
Distinguish missing Wi-Fi, unreachable device, incompatible API, rejected command,
and slave offline with useful messages. Join the ESP32 network through Android Wi-Fi
settings; automated Wi-Fi provisioning/router mode is outside scope.

Configure Android local HTTP access for the ESP32 address. Test on a real phone
joined to the ESP32 AP with no Internet. The first release presents Wi-Fi as the
supported connection; existing Bluetooth mode is disabled with an explanation.
The existing browser page also uses consistent main-controller behavior and can
coexist with app polling. LCD app online means recent foreground status polling
(existing 5000 ms timeout), with master/slave link shown separately.

## File boundaries and verification

Firmware changes center on master_wifi.ino, web_bridge.h, master_controller.h/.ino,
master_audio.ino, audio_monitor.h and small portable API/command/motor helpers.
The slave packet format need not change: report needed fields from current master
telemetry/outputs and preserve slave firmware/pin settings unless a verified need
arises. Keep shared protocol copies equal and retain existing diagnostic logs.

App changes center on services/wifi_client.dart, connection_manager.dart,
models/esp_state.dart, providers/diorama_provider.dart and music_provider.dart,
affected control/connect/home/flag/music tabs, and Android network configuration.
Replace the obsolete MyApp counter-template test with actual startup/model coverage;
retain the intro-layout regression test and local Bluetooth build compatibility copy.

Tests must cover valid/malformed/stale JSON, API versions, accepted vs applied,
duplicate IDs, stale boot IDs, mode races, superseded commands, pump ACK failure,
sound pulses between polls, physical button synchronization, polling single-flight,
connection loss/resume, disposal, audio pause/error/completion, stopped/expired
lease replay, held controls, joystick takeover, 5000 ms motion cap and timer wrap.
Run full firmware host tests, both relevant firmware builds, Flutter analysis and
full tests, then Android debug APK build. Maintain a documented request/response
fixture shared between firmware contract tests and Dart parsing tests.

On hardware, test manual/auto controls with physical buttons, sensor updates,
pump confirmations, SD audio, flag stop/release/background/disconnect, master/slave
reset, one-way loss, slow HTTP clients, app without Internet and LCD app status.
Prepare a reviewable firmware build/APK before flashing/installing. Existing phone
installation authorization persists; actual hardware tests require connected devices
and must be reported as pending when unavailable.

## Approved defaults

Wi-Fi-only is selected. Builder-proposed defaults are: two initial SD tracks,
live device playback as the first-release music output, unsupported narration
disabled, joystick priority, 1000 ms motion leases, and a 5000 ms continuous app
movement cap. These defaults were approved with this design.
