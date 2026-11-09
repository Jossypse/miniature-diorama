# Dancing Fountain Implementation Plan

> Execute inline using the existing superpowers workflow. User requested implementation directly; no additional design approval is needed for the stated behavior.

**Goal:** Sound + Fountain runs both pumps in alternation; remove independent pump buttons from the mobile app.
**Spec:** User request2026-11-04: alternate on/off every3-5seconds; Sound + Fountain owns pump activation. Choose4seconds per pump. Keep the separate fountain LED strip control. Audio stop/pause/completion/error, show cancellation or link failure ends the show with both pumps off.
**Architecture:** Extend existing CombinedAction state machine using its nonblocking tick and reliable relay ACKs. Queue one final two-relay mask per transition using the existing link controller; no ESP-NOW protocol or pin changes. Start with pump1, wait for ACK and verified audio, alternate one pump at a time every4000ms measured after ACK. Do not queue new phases while a relay command is pending. Both pumps are show-owned; independent legacy relay actions cancel the show before executing.
**Files:** combined_action.h (scheduler), wifi_controller.h (both-relay cancellation/result concern), master_config.h/masterminiature.ino (4s configuration), tests/test_combined.cpp and test_wifi_controller.cpp (timing/stop/error/ownership); app ControlTab and widget tests (four tiles only), DioramaProvider (matching demo alternation).

- [x] Write failing firmware tests for4s alternation, ACK gating, delayed ACK, timer rollover and both-pump cancellation.
- [x] Implement scheduling and controller result ownership; run host suite.
- [x] Update app test to require Sound + Fountain and no Pump1/Pump2 tiles; remove tiles and mirror alternation in explicit demo mode.
- [x] Run app tests/analyzer, build APK and master firmware; keep persistent DFPlayer diagnostics from fa9aece.
- [x] Install APK and upload verified master to identified COM13; confirm live relay masks/stop over API. Retain all rollback history. Record unavailable physical flow checks explicitly.

Verification so far: firmware14/14 host executables passed; Flutter29/29 tests passed; analyzer clean after one test-only brace fix; APK built. Final master compilation and one independent read-only review are in progress. No ESP-NOW wire or slave changes. The original restored Music UI remains intact. DFPlayer startup/idle captures remained clean; recurring audio root cause is still unconfirmed, and persistent diagnostics are included to retain the next raw error.

Final master compilation passed. Independent review had no blocking findings; the documentation clarification was addressed. APK installation completed. Master upload/live test await USB reconnect after COM13 disappeared.

Completion: master flashed/verified at115200baud on COM13; API sequence1->2->1 and OFF0 confirmed, audio playing during show and stopped after OFF; user confirmed both physical pumps alternate. Detailed evidence is in docs/implementation/dancing-fountain.md. Intermittent idle audio fault remains unproven; persistent diagnostics are installed.
