import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dioramaapp/services/wifi_client.dart';
import 'package:dioramaapp/models/api_command.dart';

void main() {
  test(
    'client requests versioned state and posts typed command once',
    () async {
      int posts = 0;
      final client = WifiClient(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            expect(request.url.path, '/api/v1/status');
            return http.Response(
              File('test/fixtures/wifi_api/status_manual.json')
                  .readAsStringSync(),
              200,
            );
          }
          posts++;
          expect(request.url.path, '/api/v1/commands');
          expect(jsonDecode(request.body)['args']['enabled'], true);
          return http.Response(
            File('test/fixtures/wifi_api/result_pending.json')
                .readAsStringSync(),
            202,
          );
        }),
      );
      expect((await client.fetchStatus()).automatic, false);
      final result = await client.submit(
        const ApiCommand(
          id: 'phone_1',
          bootId: 'a1b2c3d4',
          action: 'light.set',
          args: {'target': 'fountain', 'enabled': true},
        ),
      );
      expect(result.status, 'pending');
      expect(posts, 1);
      client.dispose();
    },
  );
  test('mode rejection and HTML response are not success', () async {
    final c = WifiClient(
      client: MockClient(
        (_) async => http.Response(
          '{"apiVersion":1,"error":{"code":"MODE_REJECTED","message":"Manual required"}}',
          409,
        ),
      ),
    );
    await expectLater(
      c.submit(
        const ApiCommand(
          id: 'x',
          bootId: 'a1b2c3d4',
          action: 'light.set',
          args: {},
        ),
      ),
      throwsA(isA<ApiException>()),
    );
    c.dispose();
    final bad = WifiClient(
      client: MockClient(
        (_) async => http.Response('<html>not a device</html>', 200),
      ),
    );
    await expectLater(bad.fetchStatus(), throwsA(isA<ApiException>()));
    bad.dispose();
  });
}
