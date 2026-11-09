import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dioramaapp/providers/diorama_provider.dart';
import 'package:dioramaapp/models/device_status.dart';
import 'package:dioramaapp/ui/tabs/control_tab.dart';
import 'package:dioramaapp/ui/tabs/home_tab.dart';

void main() {
  testWidgets('all sensor tiles become unknown after stale poll', (
    tester,
  ) async {
    final p = DioramaProvider();
    p.state.applyDeviceStatus(
      DeviceStatus.fromJson(
        jsonDecode(
          File('test/fixtures/wifi_api/status_manual.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: p,
        child: const MaterialApp(home: Scaffold(body: HomeTab())),
      ),
    );
    expect(find.text('RED'), findsOneWidget);
    p.state.stale('timeout');
    await tester.pump();
    expect(find.text('RED'), findsNothing);
    expect(find.text('unknown'), findsNWidgets(3));
    await tester.pumpWidget(const SizedBox.shrink());
    p.dispose();
  });

  testWidgets(
    'fountain lights stay separate and Sound + Fountain is the only pump control',
    (tester) async {
      final p = DioramaProvider();
      p.state.applyDeviceStatus(
        DeviceStatus.fromJson(
          jsonDecode(
            File('test/fixtures/wifi_api/status_slave_offline.json')
                .readAsStringSync(),
          ) as Map<String, dynamic>,
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: p,
          child: const MaterialApp(home: Scaffold(body: ControlTab())),
        ),
      );
      expect(find.text('FOUNTAIN LIGHTS'), findsOneWidget);
      expect(
        tester
            .widget<GridView>(find.byType(GridView))
            .childrenDelegate
            .estimatedChildCount,
        4,
      );
      expect(find.text('SOUND + FOUNTAIN'), findsOneWidget);
      expect(find.text('PUMP 1'), findsNothing);
      expect(find.text('PUMP 2'), findsNothing);
      expect(find.text('UNKNOWN'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      p.dispose();
    },
  );
}
