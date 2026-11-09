import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dioramaapp/providers/diorama_provider.dart';
import 'package:dioramaapp/providers/music_provider.dart';
import 'package:dioramaapp/models/device_status.dart';
import 'package:dioramaapp/models/command_result.dart';
import 'package:dioramaapp/ui/tabs/music_tab.dart';

class RecordingDevice extends DioramaProvider {
  final List<int> plays = [];
  @override
  Future<ActionOutcome> playTrackId(int id) async {
    plays.add(id);
    return ActionOutcome(
      result: CommandResult.fromJson({
        'apiVersion': 1,
        'bootId': 'a1b2c3d4',
        'id': 'test',
        'status': 'applied',
        'reason': null,
        'acceptedAtMs': 0,
        'finishedAtMs': 1,
      }),
    );
  }
}

void main() {
  testWidgets(
    'unavailable playlist tap explains why instead of silently doing nothing',
    (tester) async {
      final p = RecordingDevice();
      final j = jsonDecode(
        File('test/fixtures/wifi_api/status_manual.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      j['audio']['ready'] = false;
      j['audio']['state'] = 'error';
      j['audio']['lastError'] = 'AUDIO_UNAVAILABLE';
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      final m = MusicProvider()..bind(p);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DioramaProvider>.value(value: p),
            ChangeNotifierProvider<MusicProvider>.value(value: m),
          ],
          child: const MaterialApp(home: Scaffold(body: MusicTab())),
        ),
      );
      await tester.ensureVisible(find.text('PLAY AUDIO HISTORY'));
      await tester.tap(find.text('PLAY AUDIO HISTORY'));
      await tester.pump();
      expect(p.plays, isEmpty);
      expect(
        find.textContaining('device reports an audio error'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      m.dispose();
      p.dispose();
    },
  );

  testWidgets(
    'original music layout dispatches each playlist once over existing integration',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final p = RecordingDevice();
      p.state.applyDeviceStatus(
        DeviceStatus.fromJson(
          jsonDecode(
            File('test/fixtures/wifi_api/status_manual.json')
                .readAsStringSync(),
          ) as Map<String, dynamic>,
        ),
      );
      final m = MusicProvider()..bind(p);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DioramaProvider>.value(value: p),
            ChangeNotifierProvider.value(value: m),
          ],
          child: const MaterialApp(home: Scaffold(body: MusicTab())),
        ),
      );
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.textContaining('Phone'), findsOneWidget);
      expect(find.textContaining('Diorama'), findsOneWidget);
      await tester.tap(find.text('PLAY AUDIO HISTORY'));
      await tester.pump();
      expect(p.plays, [1]);
      await tester.ensureVisible(find.text('PLAY XMAS AUDIO'));
      await tester.tap(find.text('PLAY XMAS AUDIO'));
      await tester.pump();
      expect(p.plays, [1, 2]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      m.dispose();
      p.dispose();
    },
  );
}
