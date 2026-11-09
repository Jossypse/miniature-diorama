# Implementation ledger — miniature-functions plan

Plan: ../superpowers/plans/2026-11-03-miniature-functions.md
Spec approved; implementation plan approved. Baselines c7b6b06 / 6716aa3.

Ruling: Work on feature/miniature-functions branches in the two existing sketch directories, keeping main and baseline tags unchanged. This preserves Arduino sketch folder names and sibling tooling paths; rollback uses Git. No separate worktrees or automatic merges.
Ruling: User subsequently requested Git histories, superseding the plan's earlier no-repository assumption. Commit milestones in both repositories.
Pre-flight: protocol feeds controller, master/slave transport and status; no conflicting consumers. Combined action owns audio/relay1 only; independent relay2 leaves it intact.
Task 1: in progress; establishing host/compiler tools and packet tests.

Task 1: complete. MSVC 14.51 host tests; bundled Arduino CLI; installed Espressif core 3.3.12. Fixed-width packet ABI is 35 bytes. Config headers enforce pin uniqueness.
Task 2: complete. Controller/debounce tests observed failing then passing; actual motor adapter test covers assigned outputs, reversal and stop. NeoPixel/RGB effects use timestamps.
Task 3: complete. Reliable link and combined tests observed failing then passing; explicit boot sessions, retired-session cache, retry exhaustion resets link and permits slave watchdog shutdown.
Task 4: complete in code. Slave controller is in shared reliable_link.h rather than a separate slave_controller.h; tests are test_link.cpp/test_color.cpp. Calibration and physical sensor/relay/LCD checks remain bench work.
Task 5: complete in code. App freshness, LCD formatting, logs, escaping and mode restrictions tested in test_feedback.cpp. Actual browser/physical checks remain pending.
Task 6: in progress. Initial ESP32 Dev Module builds passed both sketches; rebuilding after review fixes. No hardware flashed.

Independent review identified four material defects; reproduced link ordering/expiration and audio silence with failing tests, then fixed them. HTTP parser blocking is established by inspection of installed WebServer 3.3.12; moved HTTP into a separate RTOS worker with queued actions and immutable status snapshots. Actual slow-client hardware probe is on bench checklist.
Ruling: Use bounded asynchronous DFPlayer state queries because startup readiness cannot detect unplugged hardware. A one-second missing playing-state deadline cancels combined action; compatible modules must implement standard 0x42 feedback or playback will be rejected.
Ruling: Natural track completion stops the combined pump action, preventing an unattended pump after the show ends. Cost if a continuous fountain was desired: user must use independent pump controls.
Ruling: Retain the most recent four retired slave boot sessions to reject delayed discovery packets without unbounded storage. Random 32-bit boot IDs plus protocol target matching are freshness protection, not authentication against forged packets.
Ruling: No connected hardware/board model was supplied. Compile for generic classic ESP32 Dev Module core 3.3.12 and leave calibration, relay polarity, pixel counts and flag travel bounds explicitly pending.

Task 6: complete for software handoff. Final host suite: 8/8 executables passed; synchronized protocol/link/feedback headers verified. Final master build exit 0: 976416 bytes flash, 50848 bytes RAM. Final slave build exit 0: 922184 bytes flash, 47448 bytes RAM. Slave library emits its architecture compatibility warning; compilation succeeds. See verification.md and bench checklist. No hardware flashed, no browser-to-device or electrical checks claimed.
Final review: four material findings addressed in one fix pass. No deferred minor findings. No remote/push/merge performed; retain both feature branches and original main/baseline tags for rollback.
