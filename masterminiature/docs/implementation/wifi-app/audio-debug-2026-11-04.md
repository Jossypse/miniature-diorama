# Device music debugging - 2026-11-04

Requested: investigate app playback using systematic debugging.

Observed failure: phone stayed on ESP32_Master_Diorama, API returned HTTP200 with audio.ready=false, state=error, trackId=null, lastError=AUDIO_UNAVAILABLE. A direct audio.play request bypassing the app returned HTTP503 AUDIO_UNAVAILABLE. Thus the app-side readiness gate reflected a device failure, not a disconnected Music tile callback.

Master identified on COM13, CH340 USB serial, STA MAC40:22:D8:33:C5:40. Released the Arduino serial-monitor process to read115200baud. Existing runtime log had no new DFPlayer error: the prior error was already latched. Restarted master using serial RTS while recording startup. Serial reported DFPlayer ready, Control page http://192.168.4.1, and matching master MAC. Android switched to HeroApps after AP restart; reconnected it to ESP32_Master_Diorama.

A single explicit API play request was accepted202 while serial capture ran. Subsequent status showed ready=true, state=playing, requested=true, selected track2, lastError=null. Track2 selection occurred during the test through the current device/app state; no inference that the initial Track1 request caused that selection. User confirmed audible sound from the diorama speaker.

Conclusion: restarting the master cleared a latched DFPlayer failure, and device playback now works. The original numeric DFPlayer error was not retained in API status or captured before the restart; its initiating cause (power, SD, serial framing or module response) remains unproven. No speculative firmware changes made. Current firmware sets audio.ready=false on error and recovers on card-online/insert notification or restart; it does not autonomously retry playback.

Raw capture files are local ignored artifacts under .build/audio-*. No wiring, firmware or Android code changed in this investigation. The original restored Music interface remains installed.

## Recurrence investigation

User reported the error again while idle. Failed-boot status a4d20ee1 showed Audio error as event2 after Boot, audio.trackId=null and audio.ready=false. No track had been selected in that boot. Three warm startup captures subsequently reported DFPlayer ready; a25-second idle capture had no new audio error. User then confirmed playback was working again. This is intermittent, not a proven repaired fault.

Added persistent per-boot audio diagnostics to status: startupReady, last received type/command/value/time, last error type/command/value/time, event/error counters and decoded detail. The last error survives later card/status messages. Startup initialization failure is also captured before the library's runtime ACK-disabled setup overwrites its last-message fields. No playback/recovery/error-gating behavior changed in this diagnostic step.

Actual master_audio.ino adapter regression failed on missing retained error detail, then passed after instrumentation. Full host suite13/13 passed. Master build/upload verification pending below.

Diagnostic firmware fa9aece was included with dancing-fountain source1c3b5cf and successfully uploaded/flash-verified on COM13 at115200baud. Live audio plus alternating pumps worked and the user confirmed physical flow. The earlier intermittent idle error remains unproven; next occurrence can be inspected through audio.diagnostics in status without resetting the master.
