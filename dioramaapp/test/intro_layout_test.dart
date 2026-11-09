import 'package:dioramaapp/ui/screens/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('intro builds through its animation without parent-data errors',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntroScreen()));
    expect(tester.takeException(), isNull);
    for (final duration in [
      const Duration(milliseconds: 400),
      const Duration(seconds: 4),
      const Duration(seconds: 4),
      const Duration(seconds: 4),
      const Duration(seconds: 4),
    ]) {
      await tester.pump(duration);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Tap to begin'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
