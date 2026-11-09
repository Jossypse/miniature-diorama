# Native execution ledger — 2026-11-04-wifi-app-integration

Spec and implementation plan approved. Execution is sequential with one final independent review.
Pre-flight: API types/fixtures feed firmware serializer and Dart parser; registry feeds executor results; motor/audio feed status; lifecycle feeds held motor and music queue. No unresolved interface conflicts.
Ruling: Keep existing named sketch/app directories on feature branches, preserving the established local workflow and Arduino folder names. No merges/pushes or main-branch edits. Cost if wrong: work remains on local feature branches rather than main.
Task 1: app baseline committed; before-wifi-integration tags created; user's IR4/SOUND5 config checkpointed on slave as 34ceedb. Existing obsolete MyApp test is a known baseline failure to replace in Task8.

Tasks 2-5: API registry/strict JSON, authoritative status, held motor arbitration, queued audio and HTTP adapters implemented. Portable tests observed RED before implementation, then passed; edge tests additionally reproduced stopped-audio pause, stop queue saturation and unexecuted timeout.
Tasks 6-9: typed Flutter transport/state, lifecycle/hold controls, Wi-Fi screens and device music implemented; core/widget tests observed RED then GREEN (17 tests before expanded regressions).
Prior decision (replaced during final review): uptime-seeded motion sequence. Restart/half-range regressions showed this did not provide bounded recovery.
Ruling: Motion sequence remains monotonic across gestures but fresh clients now seed from motor.sequence and reset on boot change. This prevents bounded-history replay without uptime ambiguity. Cost if wrong: competing clients may require one status refresh and a fresh hold after a sequence rejection.

Ruling: MusicProvider binds once to DioramaProvider and derives audio/catalog from its status rather than exposing a second public audio snapshot setter. This avoids duplicate authorities; cost if wrong: provider reuse requires the shared device provider.

Final review: one independent read-only review by gpt-6-astra, master3ccb6fc..621d0f4 and app59ed30c..ebb30e4. Four Important findings reproduced; color freshness regraded Important because stale sensor values must not appear current. No Critical findings. No deferred minors.
Final: fixed relay ON/OFF/ON false confirmation - test_wifi_controller.cpp RED->GREEN; every intermediate changed relay intent irreversibly supersedes affected pending records, preserving relay2 independence.
Final: fixed queue loss during conflicting audio command - completion/busy and real volume-final-refresh regressions RED->GREEN; wait locally for busy to clear, retain failed/uncertain queue head and show error; never replay the POST automatically.
Final: fixed fresh-client/reboot/wrap motion seeding - flag_session high-water regression RED->GREEN; additional provider reboot test verifies old lease stop is not sent to the new boot.
Final: fixed demo pause/resume and queue simulation - demo regression RED->GREEN; simulation timers are demo-only and pause in background.
Final: fixed stale color label/highlight - freshness widget regression RED->GREEN. Also fixed phone-width header wrapping after navigation regression failed; app26/26 tests and analyzer clean.
Final: Ruling: Actual DFPlayer ordering/SD audio and electrical pump/motor behavior remain pending bench checks because no ESP32 USB device is connected (COM9/COM10 are Bluetooth virtual ports). Cost if wrong: wiring/module-specific behavior remains undiscovered until bench verification.
Final: Ruling: Real Android AP operation without Internet remains pending; USB APK install and connection-screen screenshot passed, but the PC is on HeroApps_5G and no updated master is connected. Cost if wrong: Android routing/actual Wi-Fi behavior still needs device validation.
Final: Ruling: Bluetooth, phone playback, narration and endpoint sensing remain excluded as approved. Cost if wrong: adding any requires another scoped implementation/hardware change.
Task10: host12/12, Flutter26/26, analyzer clean, shared fixtures match; both final firmware builds and APK rebuild passed. Final APK installed/launched on USB phone. Release hashes and source IDs recorded in .build/wifi-release/manifest.json. Physical checklist remains open explicitly.
