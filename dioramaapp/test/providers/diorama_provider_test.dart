import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dioramaapp/providers/diorama_provider.dart';
import 'package:dioramaapp/services/wifi_client.dart';
import 'package:dioramaapp/models/api_command.dart';
import 'package:dioramaapp/models/device_status.dart';

void main() {
  testWidgets(
    'demo show alternates both pumps every four seconds and stops both',
    (tester) async {
      final p = DioramaProvider()..enableDemoMode();
      await p.setCombined(true);
      expect(p.pumpOn(1), true);
      expect(p.pumpOn(2), false);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(p.pumpOn(1), false);
      expect(p.pumpOn(2), true);
      await p.setCombined(false);
      expect(p.pumpOn(1), false);
      expect(p.pumpOn(2), false);
      await p.setCombined(true);
      await p.pauseAudio();
      expect(p.pumpOn(1), false);
      expect(p.pumpOn(2), false);
      p.dispose();
    },
  );

  testWidgets(
    'master reboot resets motion counter without stopping an old lease on new boot',
    (tester) async {
      final posts = <Map<String, dynamic>>[];
      final p = DioramaProvider(
        client: WifiClient(
          client: MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            posts.add(body);
            return http.Response(
              jsonEncode({
                'apiVersion': 1,
                'bootId': body['bootId'],
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
      final j = jsonDecode(
        File('test/fixtures/wifi_api/status_manual.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      j['uptimeMs'] = 2300000000;
      j['motor']['sequence'] = 0x90000000;
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      p.flag.start(FlagDirection.raising);
      await tester.pump();
      expect(posts.single['args']['sequence'], 0x90000001);
      j['bootId'] = '12345678';
      j['uptimeMs'] = 1;
      j['motor']['sequence'] = 0;
      p.state.applyDeviceStatus(DeviceStatus.fromJson(j));
      expect(p.flag.active, false);
      expect(posts.length, 1);
      p.flag.start(FlagDirection.lowering);
      await tester.pump();
      expect(posts.last['args']['sequence'], 1);
      expect(posts.last['bootId'], '12345678');
      p.dispose();
      await tester.pump();
    },
  );

  testWidgets('confirmed status owns outputs and physical mode changes', (
    tester,
  ) async {
    final status = jsonDecode(
      File('test/fixtures/wifi_api/status_manual.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final p = DioramaProvider(
      client: WifiClient(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode(status), 200);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'apiVersion': 1,
              'bootId': body['bootId'],
              'id': body['id'],
              'status': 'applied',
              'reason': null,
              'acceptedAtMs': 1,
              'finishedAtMs': 2,
            }),
            200,
          );
        }),
      ),
    );
    await p.initialize();
    expect(p.isAutoMode, false);
    final result = await p.setLight(LightTarget.building, true);
    expect(result.applied, true);
    expect(p.state.isBuildingLightsOn, false);
    status['outputs']['building']['enabled'] = true;
    status['mode'] = 'automatic';
    await p.connectionManager.refresh();
    expect(p.state.isBuildingLightsOn, true);
    expect(p.isAutoMode, true);
    p.dispose();
  });
}
