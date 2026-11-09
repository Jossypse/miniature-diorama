import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dioramaapp/services/wifi_client.dart';
import 'package:dioramaapp/services/connection_manager.dart';
import 'package:dioramaapp/models/esp_state.dart';

String sample() =>
    File('test/fixtures/wifi_api/status_manual.json').readAsStringSync();
void main() {
  test('polls are single flight and two failures disconnect with read-only recovery', () async {
    int calls = 0;
    bool fail = false;
    final gate = Completer<http.Response>();
    final c = WifiClient(
      client: MockClient((_) async {
        calls++;
        if (calls == 1) return gate.future;
        return http.Response(fail ? 'broken' : sample(), 200);
      }),
    );
    final s = EspState();
    final m = ConnectionManager(s, client: c);
    final first = m.connectWifi();
    await Future<void>.delayed(Duration.zero);
    final second = m.refresh();
    expect(calls, 1);
    gate.complete(http.Response(sample(), 200));
    await first;
    await second;
    expect(s.isConnected, true);
    expect(s.isAutoMode, false);
    fail = true;
    await m.refresh();
    expect(s.dataStale, true);
    expect(s.isConnected, true);
    await m.refresh();
    expect(s.isConnected, false);
    fail = false;
    await m.refresh();
    expect(s.isConnected, true);
    expect(s.dataStale, false);
    m.dispose();
    s.dispose();
  });
  test('late connection response after disconnect is ignored', () async {
    final gate = Completer<http.Response>();
    final s = EspState();
    final m = ConnectionManager(
      s,
      client: WifiClient(client: MockClient((_) => gate.future)),
    );
    final pending = m.connectWifi();
    await Future<void>.delayed(Duration.zero);
    await m.disconnect();
    gate.complete(http.Response(sample(), 200));
    await pending;
    expect(s.isConnected, false);
    m.dispose();
    s.dispose();
  });
}
