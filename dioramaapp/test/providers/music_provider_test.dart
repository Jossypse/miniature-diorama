import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dioramaapp/services/wifi_client.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:dioramaapp/providers/music_provider.dart';
import 'package:dioramaapp/providers/diorama_provider.dart';
import 'package:dioramaapp/models/device_status.dart';
import 'package:dioramaapp/models/command_result.dart';
import 'package:dioramaapp/models/music_track.dart';

class RecordingDevice extends DioramaProvider {
  final List<int> plays = [];
  @override
  Future<ActionOutcome> playTrackId(int id) async {
    plays.add(id);
    return const ActionOutcome(failure: 'test failure');
  }
}

Map<String, dynamic> sample() => jsonDecode(
  File('test/fixtures/wifi_api/status_manual.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  testWidgets(
    'volume command final refresh may advance completion without dropping queue',
    (tester) async {
      final j = sample();
      final posts = <String>[];
      final p = DioramaProvider(
        client: WifiClient(
          client: MockClient((req) async {
            if (req.method == 'GET') return http.Response(jsonEncode(j), 200);
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            posts.add(body['action'] as String);
            if (body['action'] == 'audio.volume') {
              j['audio']['completionSequence'] = 1;
            }
            return http.Response(
              jsonEncode({
                'apiVersion': 1,
                'bootId': j['bootId'],
                'id': body['id'],
                'status': 'applied',
                'reason': null,
                'acceptedAtMs': 0,
                'finishedAtMs': 1,
              }),
              200,
            );
          }),
        ),
      );
      final m = MusicProvider()..bind(p);
      await p.initialize();
      m.addToQueue(m.library.last);
      await m.setVolume(50);
      for (var i = 0; i < 12; i++) {
        await tester.pump();
      }
      expect(posts, ['audio.volume', 'audio.play']);
      expect(m.queue, isEmpty);
      expect(m.queueError, isNull);
      m.dispose();
      p.dispose();
    },
  );

  testWidgets(
    'completion waits for volume busy state and retains failed queue entry',
    (tester) async {
      final p = RecordingDevice();
      final m = MusicProvider()..bind(p);
      final j = sample();
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      m.addToQueue(m.library.last);
      p.state.pending.add('audio_pump1');
      j['audio']['completionSequence'] = 1;
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      await tester.pump();
      expect(p.plays, isEmpty);
      expect(m.queue.length, 1);
      p.state.pending.clear();
      p.state.changed();
      await tester.pump();
      expect(p.plays, [2]);
      expect(m.queue.length, 1);
      expect(m.queueError, isNotNull);
      p.state.changed();
      await tester.pump();
      expect(p.plays, [2]);
      m.dispose();
      p.dispose();
    },
  );
  testWidgets('demo pause resumes and simulated completion advances queue', (
    tester,
  ) async {
    final p = DioramaProvider();
    p.enableDemoMode();
    final m = MusicProvider()..bind(p);
    await m.playTrack(m.library.first);
    expect(m.phase, 'playing');
    await m.pause();
    expect(m.phase, 'paused');
    await m.resume();
    expect(m.phase, 'playing');
    m.addToQueue(m.library[1]);
    for (var i = 0; i < 1550; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(m.currentTrack?.trackId, 2);
    expect(m.queue, isEmpty);
    m.dispose();
    p.dispose();
  });

  testWidgets(
    'queue advances once for fresh completion, never reconnect or background',
    (tester) async {
      final p = RecordingDevice();
      final m = MusicProvider()..bind(p);
      final j = sample();
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      m.addToQueue(m.library.last);
      m.addToQueue(m.library.first);
      j['audio']['completionSequence'] = 1;
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      await tester.pump();
      expect(p.plays, [2]);
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      await tester.pump();
      expect(p.plays, [2]);
      p.state.stale('offline', offline: true);
      j['audio']['completionSequence'] = 2;
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      await tester.pump();
      expect(p.plays, [2]);
      p.setForeground(false);
      j['audio']['completionSequence'] = 3;
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      await tester.pump();
      expect(p.plays, [2]);
      m.dispose();
      p.dispose();
    },
  );
  testWidgets('unsupported queued track cannot be dispatched', (tester) async {
    final p = RecordingDevice();
    final m = MusicProvider()..bind(p);
    p.state.applyDeviceStatus(DeviceStatus.fromJson(sample()));
    const unknown = MusicTrack(
      title: 'unsupported',
      subtitle: '',
      durationSeconds: 0,
      triggerCommand: 'audio_play_99',
    );
    m.addToQueue(unknown);
    expect(m.queue, isEmpty);
    final r = await m.playTrack(unknown);
    expect(r.applied, false);
    expect(p.plays, isEmpty);
    m.dispose();
    p.dispose();
  });

  testWidgets('device music reflects reported pause and supported catalog', (
    tester,
  ) async {
    final p = DioramaProvider();
    final m = MusicProvider();
    m.bind(p);
    final json = jsonDecode(
      File('test/fixtures/wifi_api/status_audio_paused.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    p.state.applyDeviceStatus(DeviceStatus.fromJson(json));
    expect(m.isPlaying, false);
    expect(m.phase, 'paused');
    expect(m.library.length, 2);
    expect(m.currentTrack?.title, 'Track 1');
    p.state.stale('offline', offline: true);
    expect(m.canPlay, false);
    m.dispose();
    p.dispose();
  });
}
