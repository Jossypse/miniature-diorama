import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dioramaapp/providers/diorama_provider.dart';
import 'package:dioramaapp/ui/tabs/flag_tab.dart';

void main() {
  testWidgets('live flag screen does not invent a height percentage', (
    tester,
  ) async {
    final p = DioramaProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: p,
        child: const MaterialApp(home: Scaffold(body: FlagTab())),
      ),
    );
    expect(find.text('Position unavailable'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    p.dispose();
  });
}
