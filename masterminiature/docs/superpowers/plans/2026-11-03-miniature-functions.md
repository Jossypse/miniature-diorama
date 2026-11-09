# Miniature Functions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Complete the approved automatic and manual functions across both ESP32 sketches.

**Architecture:** Retain Arduino tabs and separate master/slave responsibilities. Extract hardware-independent controller and protocol logic into small C++ headers used by firmware and host tests. Queue received packets and perform peripheral work in the normal loop.

**Tech Stack:** ESP32 Arduino C++, ESP-NOW, Adafruit_NeoPixel, DFRobotDFPlayerMini, LiquidCrystal_I2C, WebServer; Python test runner invoking an available C++ compiler.

**Spec:** `../specs/2026-11-03-miniature-functions-design.md` (approved).

## Global Constraints

- Master buttons 1–5: GPIO 13,12,14,27,26; fountain GPIO33; building GPIO25.
- Motor AIN1=18, AIN2=5, PWMA=4. No software STBY assignment.
- Preserve DFPlayer RX17/TX16, RGB19/21/22, slave sensor/relay assignments.
- NeoPixels: NEO_GRB + NEO_KHZ800, brightness 50, independently configurable counts initially 30.
- Debounce 30 ms; sound hold 2000 ms; heartbeat 200 ms; link stale at 1000 ms.
- App stale at 5000 ms; command retry 250 ms with three retries after initial send.
- Never restore pumps automatically on reconnect; new peer sessions invalidate pending activations.
- No firmware flashing or physical-operation claims without hardware verification.
- User subsequently authorized local Git histories: commit the implementation on feature branches in both repositories; preserve main and baseline-before-features.

## Review Focus

1. Stale or reordered ON packets must not reactivate a pump after a reboot/link loss (Task 1/4).
2. A button held through boot or mode transition must not trigger repeated actions (Task 2).
3. Missing TCS pulses must not block relay heartbeats or fabricate color (Task 4).
4. A web override during combined playback must leave pump/audio state consistent (Task 3/5).
5. Timer rollover must preserve debounce, sound hold, and timeout behavior (Task 1/2).

## Task 1: Protocol, configuration, and reproducible test runner

**Files:** create `miniature_protocol.h`, `master_config.h`, `tests/test_protocol.cpp`, `tests/run_tests.py`; create sibling `../slaveminiature/miniature_protocol.h` and `slave_config.h`.

**Interfaces:** `enum class MessageKind`, fixed-width `Packet`, `bool validatePacket(const Packet&, size_t)`, `bool elapsed(uint32_t now,uint32_t since,uint32_t interval)`, `bool newerSequence(uint32_t candidate,uint32_t previous)`. Packet has protocol version, sender boot session, target boot session, sequence, kind, typed telemetry/status and bounded event identifier. No raw String objects on wire.

- [x] Write tests rejecting wrong size/version/kind, invalid joystick/color values, stale sequence and wrong target session; accept valid packets and sequence/timer rollover. Run and observe expected missing-feature failures.
- [x] Implement protocol validation and configuration headers with static pin-uniqueness checks and explicit polarity/channel settings. Use one canonical protocol copied into each self-contained sketch.
- [x] Build/run host tests using the installed ESP32 toolchain's host compiler if available, otherwise obtain a local host toolchain; do not substitute source-pattern checks for behavior tests. Python runner compares both protocol copies byte-for-byte.
- [x] Verify protocol tests pass and record commands/tool versions. Locate bundled Arduino CLI and installed libraries/core; core 3.3.12 exists locally, but actual board model is still unconfirmed.

## Task 2: Master controller, buttons, lighting, motor

**Files:** create `master_controller.h`, `master_controller.ino`, `tests/test_controller.cpp`; modify `masterminiature.ino`, `master_buttons_rgb.ino`, `master_leds.ino`, `master_motor.ino`; retire unused contents of `master_sensors.ino` with an explanatory comment.

**Interfaces:** `Controller::press(uint8_t button,uint32_t now)`, `Controller::tick(uint32_t now,const SensorState&)`, `Controller::setMode(bool automatic,uint32_t now)`, `Outputs` for fountain color, building/RGB enable and motor direction. `DebouncedButton::update(bool pressed,uint32_t now)` emits one press after 30 ms; initial held buttons must first be released. Controller is independent of Arduino peripherals.

- [x] Write tests for each manual button, automatic mode ownership, mode-transition reset, IR removal, sound hold/retrigger, missing/invalid color, joystick deadband, stale telemetry, initial held buttons and millis rollover; observe failures.
- [x] Implement the pure controller and debounce state, then run controller/protocol tests to green.
- [x] Adapt setup/loop to initialize all outputs before callbacks. Apply NeoPixel fills only on changes; use bounded, time-based RGB cycling without delay. Initialize motor PWM zero before direction/enable use.
- [x] Test output adapters with a minimal fake HAL for requested colors and motor stop; preserve manual-only joystick operation and document physical travel-limit requirement.

## Task 3: Master link, audio and combined fountain action

**Files:** modify `master_espnow.ino`, `master_audio.ino`, `master_controller.ino`; create `reliable_link.h`, `tests/test_link.cpp`, `tests/test_combined.cpp`.

**Interfaces:** `ReliableLink::receive(const Packet&,uint32_t now)`, `ReliableLink::tick(uint32_t now)`, `ReliableLink::requestRelay(uint8_t relay,bool on,uint32_t now)` returns acceptance; `toggleCombined()`, `cancelCombined()`, `serviceAudio()`, and `logEvent(EventCode)` are main-loop operations.

- [x] Write tests for handshake, ack matching, wrong sessions, duplicate/out-of-order acknowledgments, three retries, retry exhaustion, stale telemetry and peer reboot; no pending ON survives reconnection.
- [x] Write combined-action tests: unavailable audio rejects activation; pump failure or audio error stops both; independent audio/relay1 commands cancel both first, relay2 leaves combined state intact. Observe failures before implementation.
- [x] Implement queue-only receive callback with sender/length validation; configure explicit channel, check ESP-NOW return codes, process queues in loop. Avoid send-callback version coupling where not needed; use application acknowledgments.
- [x] Implement readiness-aware DFPlayer commands and event polling; distinguish command submission from confirmed playback. Coordinate pump activation/ack and audio state with explicit pending/on/off/failure states.
- [x] Run the complete host suite; test late ON ack after cancellation and repeated button5 presses while activation is pending.

## Task 4: Slave sensors, relay watchdog, acknowledgments and LCD

**Files:** modify all four slave `.ino` files; create `slave_controller.h`, `tests/test_slave.cpp`, `tests/test_color.cpp` on master test side.

**Interfaces:** `SlaveController::receive(const Packet&,uint32_t now)`, `SlaveController::tick(uint32_t now)`, `classifyColor(const ColorSample&,const ColorCalibration&)`; adapters `serviceSensors()`, `serviceSlaveLink()`, `updateLCDDisplay()` run each loop.

- [x] Write tests for relay session handshake, duplicate-safe commands, older sequence rejection, missed heartbeat shutdown, reboot handshake, ignored old-session ON; color zero/timeout, calibrated representative samples, and ambiguous/no-target rejection. Observe failures.
- [x] Implement slave controller and bounded incremental RGB pulse acquisition with settling between filter changes; cap each pulse read timeout and spread sampling over loop iterations. Capture short sound events between telemetry sends. Document externally wired TCS S0/S1 scaling, calibration and no-target threshold.
- [x] Replace delay(200) with timer-driven telemetry; publish relay output state and matching acknowledgments. Heartbeat absence sets both relays OFF and requires a fresh handshake plus new user command.
- [x] Configure LCD I2C explicitly; pad/clip rows to 16 characters, show independent app/link status, rotate bounded latest-event/relay rows, avoid repeated clear. Test formatting helpers and event transition deduplication.
- [x] Run all host tests, including no pulses while link watchdog continues to operate. Hardware pulse timing and accuracy remain bench checks.

## Task 5: Web controls, status and shared event feedback

**Files:** modify `master_wifi.ino`, `master_controller.ino`; create `tests/test_web_control.cpp` and a manual browser checklist.

**Interfaces:** `handleAction(Action)` routes physical/web actions identically; `buildStatusJson()` exposes mode, link freshness, app status, confirmed relay outputs, pending commands, audio readiness and latest event. `/status` polling updates app freshness; unrelated HTTP requests do not imply a live app.

- [x] Write tests for auto-mode lighting rejection, shared button/web outputs, 5-second app expiration and JSON escaping; observe failures.
- [x] Keep current routes functional through the controller; add combined control and status polling. Label RGB cycling accurately. Show unavailable/pending/confirmed states separately; serialize numeric/boolean status and escaped bounded event text.
- [x] Feed mode/app/event status to slave heartbeats; never print sensor-trigger logs on every telemetry packet.
- [x] Run full tests and check app disconnect, stale slave, manual/auto controls and combined override behavior in the browser where available.

## Task 6: Compile, independent review, and wiring/bench handoff

**Files:** create `README.md`, `docs/bench-checklist.md`; update this plan's completion state and keep test evidence.

- [x] Run all host tests and compile both sketches using bundled Arduino CLI and the installed ESP32 core; use generic ESP32 Dev Module only as a documented provisional compile target until physical board is confirmed. Check all dependencies and report any compiler/library failure precisely.
- [x] Request one independent whole-change review against the approved spec. Fix material issues with reproducing tests; rerun affected tests and both builds after code changes.
- [x] Document pin tables, GPIO12 boot consideration, NeoPixel count/power, RGB/relay/sensor polarity, motor driver enable requirement, STA peer MACs, radio channel, DFPlayer files, external TCS scaling and calibration procedure.
- [x] Provide bench checklist for all five buttons, held buttons, each sensor, strip colors, joystick direction/limits, ack loss, board resets, reconnection, LCD logs, app timeout and audio failures. Mark physical tests unperformed unless actually executed.
- [x] Report changed sketches, test/build evidence, remaining hardware checks and any differences from the approved spec. No flashing or publishing.

## Plan review

The six tasks cover all approved functions. Integration runs sequentially because controller,
protocol, slave status and web controls share interfaces. Host tests cover controller/transport
logic; they do not establish electrical compatibility, physical color accuracy, pump operation
or flag travel. This plan does not change the approved behavior defaults.
