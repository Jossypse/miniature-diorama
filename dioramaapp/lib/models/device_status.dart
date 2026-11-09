Map<String, dynamic> objectValue(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

bool boolValue(dynamic v) {
  if (v is! bool) throw const FormatException('Expected boolean');
  return v;
}

int intValue(dynamic v) {
  if (v is! int || v < 0 || v > 0xffffffff) {
    throw const FormatException('Expected unsigned integer');
  }
  return v;
}

String stringValue(dynamic v) {
  if (v is! String) throw const FormatException('Expected string');
  return v;
}

String enumValue(dynamic v, List<String> values) {
  final s = stringValue(v);
  if (!values.contains(s)) throw const FormatException('Unknown state');
  return s;
}

void requireApi(Map<String, dynamic> json) {
  if (json['apiVersion'] is! int || json['apiVersion'] != 1) {
    throw const FormatException('Incompatible device API');
  }
  if (!RegExp(r'^[0-9a-f]{8}$').hasMatch(stringValue(json['bootId']))) {
    throw const FormatException('Invalid boot ID');
  }
}

class DeviceTrack {
  final int id;
  final String title;
  const DeviceTrack(this.id, this.title);
}

class DeviceAudio {
  final bool ready, requested;
  final String state;
  final int? trackId;
  final int volume, completionSequence;
  final String? error;
  DeviceAudio.fromJson(Map<String, dynamic> j)
    : ready = boolValue(j['ready']),
      requested = boolValue(j['requested']),
      state = enumValue(j['state'], [
        'stopped',
        'starting',
        'playing',
        'paused',
        'error',
      ]),
      trackId = j['trackId'] == null ? null : intValue(j['trackId']),
      volume = intValue(j['volumePercent']),
      completionSequence = intValue(j['completionSequence']),
      error = j['lastError'] == null ? null : stringValue(j['lastError']) {
    if (volume > 100) throw const FormatException('Invalid volume');
  }
}

class DeviceStatus {
  final String bootId;
  final int revision, uptimeMs;
  final bool automatic,
      appOnline,
      slaveOnline,
      sensorsFresh,
      relaysKnown,
      relayPending;
  final int? telemetryAgeMs, joyY, confirmedRelays;
  final int desiredRelays;
  final String? color;
  final bool? ir, soundDetected;
  final int soundSequence;
  final int? soundAgeMs;
  final bool fountainOn, buildingOn, rgbOn;
  final String fountainColor, combinedState, motorDirection, motorOwner;
  final int leaseRemainingMs, motionSequence;
  final int? positionPercent;
  final DeviceAudio audio;
  final List<DeviceTrack> tracks;
  final Map<String, bool> capabilities;
  final List<String> logs;
  DeviceStatus._(Map<String, dynamic> j)
    : bootId = stringValue(j['bootId']),
      revision = intValue(j['revision']),
      uptimeMs = intValue(j['uptimeMs']),
      automatic = enumValue(j['mode'], ['automatic', 'manual']) == 'automatic',
      appOnline = boolValue(objectValue(j['app'])['online']),
      slaveOnline = boolValue(objectValue(j['slave'])['connected']),
      telemetryAgeMs = objectValue(j['slave'])['ageMs'] == null
          ? null
          : intValue(objectValue(j['slave'])['ageMs']),
      sensorsFresh = boolValue(objectValue(j['sensors'])['fresh']),
      joyY = objectValue(j['sensors'])['joyY'] == null
          ? null
          : intValue(objectValue(j['sensors'])['joyY']),
      color = objectValue(j['sensors'])['color'] == null
          ? null
          : enumValue(objectValue(j['sensors'])['color'], [
              'NONE',
              'RED',
              'GREEN',
              'BLUE',
              'YELLOW',
              'WHITE',
            ]),
      ir = objectValue(j['sensors'])['ir'] == null
          ? null
          : boolValue(objectValue(j['sensors'])['ir']),
      soundDetected =
          objectValue(objectValue(j['sensors'])['sound'])['detected'] == null
          ? null
          : boolValue(
              objectValue(objectValue(j['sensors'])['sound'])['detected'],
            ),
      soundSequence = intValue(
        objectValue(objectValue(j['sensors'])['sound'])['sequence'],
      ),
      soundAgeMs =
          objectValue(objectValue(j['sensors'])['sound'])['lastTriggerAgeMs'] ==
              null
          ? null
          : intValue(
              objectValue(
                objectValue(j['sensors'])['sound'],
              )['lastTriggerAgeMs'],
            ),
      fountainOn = boolValue(
        objectValue(objectValue(j['outputs'])['fountain'])['enabled'],
      ),
      fountainColor = enumValue(
        objectValue(objectValue(j['outputs'])['fountain'])['color'],
        ['NONE', 'RED', 'GREEN', 'BLUE', 'YELLOW', 'WHITE'],
      ),
      buildingOn = boolValue(
        objectValue(objectValue(j['outputs'])['building'])['enabled'],
      ),
      rgbOn = boolValue(
        objectValue(objectValue(j['outputs'])['rgb'])['enabled'],
      ),
      relaysKnown = boolValue(
        objectValue(objectValue(j['outputs'])['relays'])['known'],
      ),
      relayPending = boolValue(
        objectValue(objectValue(j['outputs'])['relays'])['pending'],
      ),
      confirmedRelays =
          objectValue(objectValue(j['outputs'])['relays'])['confirmed'] == null
          ? null
          : intValue(
              objectValue(objectValue(j['outputs'])['relays'])['confirmed'],
            ),
      desiredRelays = intValue(
        objectValue(objectValue(j['outputs'])['relays'])['desired'],
      ),
      combinedState = enumValue(objectValue(j['combined'])['state'], [
        'off',
        'starting',
        'active',
        'failed',
      ]),
      motorDirection = enumValue(objectValue(j['motor'])['direction'], [
        'stopped',
        'raising',
        'lowering',
      ]),
      motorOwner = enumValue(objectValue(j['motor'])['owner'], [
        'none',
        'joystick',
        'app',
      ]),
      motionSequence = intValue(objectValue(j['motor'])['sequence']),
      leaseRemainingMs = intValue(objectValue(j['motor'])['leaseRemainingMs']),
      positionPercent = objectValue(j['motor'])['positionPercent'] == null
          ? null
          : intValue(objectValue(j['motor'])['positionPercent']),
      audio = DeviceAudio.fromJson(objectValue(j['audio'])),
      tracks = _tracks(objectValue(j['capabilities'])['tracks']),
      capabilities = _capabilities(objectValue(j['capabilities'])),
      logs = _logs(j['logs']) {
    if (joyY != null && joyY! > 4095 ||
        desiredRelays > 3 ||
        confirmedRelays != null && confirmedRelays! > 3 ||
        leaseRemainingMs > 1000) {
      throw const FormatException('Invalid device range');
    }
    if (sensorsFresh &&
        (color == null ||
            ir == null ||
            joyY == null ||
            soundDetected == null)) {
      throw const FormatException('Fresh sensors missing');
    }
    if (!sensorsFresh &&
        (color != null ||
            ir != null ||
            joyY != null ||
            soundDetected != null)) {
      throw const FormatException('Stale sensors must be unknown');
    }
    if (relaysKnown != (confirmedRelays != null)) {
      throw const FormatException('Relay validity mismatch');
    }
    boolValue(objectValue(j['slave'])['fresh']);
    enumValue(objectValue(objectValue(j['outputs'])['rgb'])['effect'], [
      'cycle',
    ]);
  }
  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    requireApi(json);
    return DeviceStatus._(json);
  }
  static List<DeviceTrack> _tracks(dynamic v) {
    if (v is! List) throw const FormatException('Expected tracks');
    final ids = <int>{};
    return List.unmodifiable(
      v.map((e) {
        final m = objectValue(e);
        final id = intValue(m['id']);
        if (id < 1 || id > 9999 || !ids.add(id)) {
          throw const FormatException('Invalid track');
        }
        return DeviceTrack(id, stringValue(m['title']));
      }),
    );
  }

  static Map<String, bool> _capabilities(Map<String, dynamic> v) =>
      Map.unmodifiable({
        for (final k in [
          'wifi',
          'bluetooth',
          'flagApp',
          'flagPosition',
          'audioPause',
          'audioVolume',
          'autoNarration',
          'phonePlayback',
        ])
          k: boolValue(v[k]),
      });
  static List<String> _logs(dynamic v) {
    if (v is! List || v.length > 8) throw const FormatException('Invalid logs');
    return List.unmodifiable(
      v.map((e) {
        final m = objectValue(e);
        intValue(m['sequence']);
        intValue(m['code']);
        return stringValue(m['message']);
      }),
    );
  }
}
