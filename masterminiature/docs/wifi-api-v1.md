# Wi-Fi API v1

Master access point: `ESP32_Master_Diorama`, password `password123`, channel 1. Base URL `http://192.168.4.1`. The phone must remain on this network even without Internet. The slave continues using the existing 35-byte ESP-NOW v1 protocol; this integration requires a master update only if the slave already runs that protocol.

## Routes

- `GET /api/v1/status`: authoritative JSON snapshot; poll once per second, one request at a time. Version, boot ID, revision and uptime accompany mode, slave freshness, sensors, actual commanded local outputs, confirmed remote relay bits, audio, motor, capabilities and eight recent logs. GPIO outputs and relay ACKs describe software state, not measured current or pump rotation.
- `POST /api/v1/commands`: strict JSON body, maximum 512 bytes. Returns 202 pending or 200 existing terminal result.
- `GET /api/v1/commands/{id}`: 200 result, or 404 if unknown/evicted/restarted. Never replay a POST on 404 or timeout.

Example body (use the current status boot ID):
```json
{"id":"phone_123","bootId":"a1b2c3d4","action":"light.set","args":{"target":"fountain","enabled":true}}
```
IDs and lease IDs contain 1?48 ASCII letters, digits, underscores or hyphens. Boot IDs are eight lowercase hexadecimal digits. Required types are strict; extra command fields are rejected. A duplicate ID with the same normalized payload returns its original record; a changed payload returns 409. Sixteen records are retained; pending records cannot be evicted, oldest terminal records can. Idempotency lasts for the retained record and current boot.

| Action | args |
| --- | --- |
| mode.set | automatic: boolean |
| light.set | target: fountain/rgb/building, enabled: boolean |
| relay.set | relay: 1 or 2, enabled: boolean |
| combined.set | enabled: boolean |
| audio.play | trackId: 1 or 2 |
| audio.pause / audio.resume / audio.stop | empty object |
| audio.volume | percent: integer 0?100 |
| flag.move | leaseId, sequence: uint32, direction: raising/lowering |
| flag.stop | leaseId, sequence: uint32 |

Results contain apiVersion, bootId, id, status (pending/applied/failed), reason, acceptedAtMs and nullable finishedAtMs. Applied indicates controller acceptance plus required relay/audio confirmation; it cannot verify physical movement. Requests are revalidated on execution. Error responses contain apiVersion and error.code/message. Common HTTP errors: 400 malformed input, 409 conflict/boot or mode mismatch, 422 invalid arguments, 503 unavailable hardware/full queue. Pending results fail after 2000 ms.

Manual light setters reject automatic mode. Fountain manual color is blue; building is yellow; RGB cycles independently of the color sensor. Mode setters are idempotent. Combined enables track1 and owns both pumps, alternating pump1/pump2 every4000ms after relay confirmation. Only one pump is commanded on at a time. Pause, stop, playback replacement, completion or error cancels the show and turns both pumps off. Volume does not cancel it. A legacy relay.set operation first cancels the show, then applies its explicit manual setting. Pausing retains a paused standalone track. Explicit relay.set remains available for legacy browser/diagnostics; separate pump controls are removed from the Android interface.

Flag commands require manual mode and fresh joystick telemetry. Renew every 200 ms, stop on release, and use a fresh lease ID per hold. Lease expiry is 1000 ms; continuous motion is capped at 5000 ms. Sequence numbers advance across gestures within a master boot. Seed a fresh client from motor.sequence, the firmware high-water mark, and reset the local counter when bootId changes; a delayed older sequence cannot reopen motion after bounded lease-history eviction. Joystick takeover revokes app ownership. Position is always null because no position sensor exists. Direction denotes commanded motion only.

Sensors become null when stale. Sound sequence counts received asserted sound reports (not deduplicated physical claps); detected means a report within 2000 ms and lastTriggerAgeMs explains its age. Audio completionSequence advances only after the current track's finish event and stopped-state verification. Pause does not count as completion. Track labels are neutral; SD files `/mp3/0001.mp3` and `/mp3/0002.mp3` determine their content. Volume maps 0?100 to DFPlayer 0?30. Playback duration and position are unavailable.

Capabilities explicitly disable Bluetooth, phone playback, narration and measured flag position. The app ignores extra compatible status fields but rejects invalid required fields or API versions. It marks the first failed poll stale, goes offline after two, and recovers with read-only polling. Lifecycle changes invalidate pending replies and stop flag renewal. Recovery does not replay commands or missed music completions. LCD app presence expires 5000 ms after polling stops.

Canonical fixtures live under `tests/fixtures/wifi_api`; run `python tools/check_wifi_fixtures.py --app-root C:/Users/josep/Downloads/dioramaapp` to check the app copies.

Audio status also includes optional diagnostics: startupReady, event/error counters, most recent received frame, and retained lastErrorType/lastErrorCommand/lastErrorValue/lastErrorAtMs/detail. These identify the original DFPlayer error even after later status/card events; they are historical diagnostics and do not imply a current error when audio.lastError is null.
