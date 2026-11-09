import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dioramaapp/main.dart';

void main() {
  testWidgets('app opens Wi-Fi connection screen', (tester) async {
    await tester.pumpWidget(const DioramaApp(hasSeenIntro: true));
    expect(find.text('Wi-Fi connection'), findsOneWidget);
    expect(find.text('Continue offline'), findsOneWidget);
  });
  testWidgets(
    'demo navigation builds each device control screen without errors',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const DioramaApp(hasSeenIntro: true));
      await tester.ensureVisible(find.text('Continue offline'));
      await tester.tap(find.text('Continue offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (final label in ['Control', 'Flag', 'Music', 'Home']) {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
