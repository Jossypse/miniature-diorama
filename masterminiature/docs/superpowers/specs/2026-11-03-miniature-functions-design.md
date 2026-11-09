# Miniature master and slave feature design

Status: approved by user; firmware implemented. Physical validation remains pending.

## Intent and approach

Complete the user's automatic lighting, five physical buttons, joystick flag,
coordinated fountain/audio, and LCD feedback while retaining both Arduino sketches.
Keep buttons, motor, lighting, audio and web controls on the master; keep sensors,
relays and LCD on the slave. Moving the motor to the slave was considered to
resolve pin conflicts; the user's updated motor pins make that unnecessary.
Preserve existing web controls, routing them through the same controller as buttons.

## Wiring

Master: buttons 1–5 GPIO 13,12,14,27,26 respectively; fountain NeoPixel GPIO 33;
building NeoPixel GPIO 25; motor AIN1=18, AIN2=5, PWMA=4;
RGB channels 19,21,22; DFPlayer ESP RX=17, TX=16.
Remove unused master local sensor code and placeholder button GPIO 15.
Buttons connect their GPIO to ground and use pullups; verify GPIO12 boot behavior
on the actual board before deployment. No motor STBY output remains: any driver
enable/STBY wiring must match the physical module.

Slave: retain relays 23,19; joystick Y=34; IR=5; sound=4;
TCS3200 S2=25,S3=26,OUT=27. Proposed classic ESP32 LCD SDA=21,SCL=22.
TCS3200 S0/S1 must be documented as externally wired for a known scaling setting;
do not invent unconfirmed wiring. Keep sensor polarity configurable.

NeoPixel baseline from testingmoto: Adafruit_NeoPixel, NEO_GRB + NEO_KHZ800,
brightness 50. Proposed initial counts: 30 per strip, independently configurable.
Board model, actual counts, color calibration, RGB polarity, and relay polarity
require hardware verification; existing code assumes active-high relays.

## Behavior

Start in automatic mode, pumps/audio/motor off; evaluate lighting from fresh sensors.
Button presses are debounced for 30 ms and trigger once per press.
Buttons 1–3 control lighting only in manual mode; web lighting controls use the
same restriction and explain when automatic mode owns the lights.
Button 1 toggles solid blue fountain pixels; Button 2 toggles RGB color cycling;
Button 3 toggles solid yellow building pixels. Button 4 toggles mode, clears manual
lighting states and stops the motor. Entering manual mode starts lights off;
entering automatic mode reevaluates fresh telemetry.

Automatic fountain: acquire red/green/blue pulse measurements with bounded timeouts,
normalize using configurable calibration, reject absent/invalid readings and
report a supported color classification. Show that color; turn off when no valid
target is present. Supported initial classes: red, green, blue, yellow, white.
Provide serial calibration output; do not claim reliable classification before
calibration on the actual sensor. No unbounded pulse waits.

Automatic RGB: smoothly cycle colors while IR detects an object, and turn off
when detection clears. Automatic building: sound triggers yellow for 2 seconds;
subsequent sound extends the timer. These durations are proposed defaults.

Button 5 in either mode toggles a combined action: play track 1 and turn relay 1
on; toggle again stops audio and turns relay 1 off. Relay 2 retains independent
web control. Manual audio/pump web commands cancel the combined state so the next
button press is predictable. Failed pump activation must not be presented as
successful; report failure and return the combined action to off.
Proposed failure semantics: require DFPlayer readiness before combined activation;
on playback activation failure stop both outputs. Independent web audio/pump
commands first stop the combined action (audio and relay 1), then apply the request.
An independent relay 2 command does not cancel the combined action.

Joystick works in manual mode, preserving the existing requirement: above 3000
forward, below 1000 reverse, otherwise stop. Make thresholds and direction
configurable. Stop on mode transitions, invalid/stale telemetry and startup.
No end-limit switches are assigned; automatic endpoint stopping cannot be claimed.
Before loaded flag operation, establish travel limits or another verified bound.

## Communication and scheduling

Use identical fixed-width, versioned packet definitions in both sketches with
message kinds, sequence numbers, telemetry, confirmed actuator status and compact
event identifiers. Keep shared definitions synchronized with a check.
Validate source MAC, exact packet size, version and field ranges before use.
Queue packets in callbacks; perform peripherals and controller updates in loop.
Use nonblocking timing for debounce, RGB, lighting holds, telemetry and LCD refresh.

Use an explicitly configured common radio channel. Confirm configured peer MACs
match the interfaces used. Report initialization and send failures.
Telemetry/status heartbeats every 200 ms, stale timeout 1000 ms.
Pump commands require application acknowledgment; retry every 250 ms up to three
retries using duplicate-safe sequence numbers. Acknowledgments report actual commanded
relay output state, not proof of pump flow. Slave switches pumps off if master
heartbeat is absent for 1000 ms. Never restore pumps automatically after reconnect.
Master stops motor and automatic lights on stale telemetry.
Include boot session identifiers in command/ack matching. On link loss or a peer
session change, discard pending ON commands and combined activation; establish a
fresh session handshake and require a new user action to enable either pump.
Ignore delayed commands from superseded sessions.

## LCD, web and audio

Maintain a bounded event log. LCD first row shows master-link/app status and mode;
second row rotates the latest event and relay status with padded, clipped 16-character
text. Avoid clearing on every update. Logs cover buttons, modes, sensor-driven output
changes, audio, pumps and connection failures; log transitions rather than every sample.

App online means the control page has polled status within 5 seconds, not merely
that a Wi-Fi station is associated. Send that status to the slave. Distinguish
app status from master–slave link freshness. Website shows confirmed relay states,
mode, latest event and stale/error status. Track DFPlayer readiness; reject playback
when unavailable and service player error events without blocking controller work.

## Verification and completion

Compile both sketches for the confirmed ESP32 board/core; check callback signatures
against that core. Test controller behavior, debounce, timeouts, duplicate commands,
malformed packets and mode transitions with hardware-independent tests where practical.
Bench-check each sensor/output, both polarities as configured, color calibration,
all buttons including held presses, app polling timeout, link loss, dropped commands,
reboots and reconnect. Hardware checks not performed must be explicitly reported.
Do not describe compilation or physical operation as verified without evidence.

## Scope limits

No new mobile app, cloud service or motor endpoint sensing hardware is included.
NeoPixel power/driver wiring and physical connections remain hardware responsibilities.
Deliver both firmware sketches, synchronized protocol, configuration/wiring notes,
calibration instructions, and a repeatable bench checklist.
