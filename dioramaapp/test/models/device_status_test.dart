import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dioramaapp/models/device_status.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/wifi_api/$name.json').readAsStringSync())
        as Map<String, dynamic>;
void main() {
  test('manual fixture preserves actual outputs and unknown flag position', () {
    final s = DeviceStatus.fromJson(fixture('status_manual'));
    expect(s.bootId, 'a1b2c3d4');
    expect(s.automatic, false);
    expect(s.fountainOn, false);
    expect(s.positionPercent, isNull);
    expect(s.tracks.length, 2);
  });
  test('offline sensors and relay states remain unknown', () {
    final s = DeviceStatus.fromJson(fixture('status_slave_offline'));
    expect(s.ir, isNull);
    expect(s.color, isNull);
    expect(s.confirmedRelays, isNull);
    expect(s.slaveOnline, false);
  });
  test('short sound reports survive between polls', () {
    final s = DeviceStatus.fromJson(fixture('status_sound_pulse'));
    expect(s.soundSequence, 3);
    expect(s.soundDetected, true);
    expect(s.buildingOn, true);
  });
  test('invalid version and wrong boolean types are rejected', () {
    final v = fixture('status_manual');
    v['apiVersion'] = 2;
    expect(() => DeviceStatus.fromJson(v), throwsFormatException);
    v['apiVersion'] = 1.0;
    expect(() => DeviceStatus.fromJson(v), throwsFormatException);
    v['apiVersion'] = 1;
    v['slave']['connected'] = 'true';
    expect(() => DeviceStatus.fromJson(v), throwsFormatException);
  });
  test('paused audio and reboot fixtures decode', () {
    expect(
      DeviceStatus.fromJson(fixture('status_audio_paused')).audio.state,
      'paused',
    );
    expect(
      DeviceStatus.fromJson(fixture('status_boot_changed')).bootId,
      '12345678',
    );
  });
}
