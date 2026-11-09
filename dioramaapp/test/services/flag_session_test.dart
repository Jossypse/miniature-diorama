import 'package:flutter_test/flutter_test.dart';
import 'package:dioramaapp/services/flag_session.dart';
import 'package:dioramaapp/models/api_command.dart';
import 'package:dioramaapp/models/command_result.dart';

ActionOutcome success() => ActionOutcome(
  result: CommandResult.fromJson({
    'apiVersion': 1,
    'bootId': 'a1b2c3d4',
    'id': 'x',
    'status': 'applied',
    'reason': null,
    'acceptedAtMs': 0,
    'finishedAtMs': 1,
  }),
);
void main() {
  testWidgets(
    'firmware high-water seed recovers across restart and uint32 wrap',
    (tester) async {
      final sequences = <int>[];
      var high = 0x90000000;
      final f = FlagSession(
        move: (_, s, _) async {
          sequences.add(s);
          return success();
        },
        stop: (_, _) async => success(),
        canMove: () => true,
        newLease: () => 'lease',
        seedSequence: () => high,
      );
      f.resetSequence(high);
      f.start(FlagDirection.raising);
      await tester.pump();
      expect(sequences.last, 0x90000001);
      f.stop();
      high = 0;
      f.resetSequence(high);
      f.start(FlagDirection.raising);
      await tester.pump();
      expect(sequences.last, 1);
      f.stop();
      high = 0xffffffff;
      f.resetSequence(high);
      f.start(FlagDirection.lowering);
      await tester.pump();
      expect(sequences.last, 0);
      f.dispose();
    },
  );

  testWidgets('hold renews and release cancels all future renewals', (
    tester,
  ) async {
    int moves = 0, stops = 0;
    final f = FlagSession(
      move: (_, _, _) async {
        moves++;
        return success();
      },
      stop: (_, _) async {
        stops++;
        return success();
      },
      canMove: () => true,
      newLease: () => 'lease',
    );
    f.start(FlagDirection.raising);
    await tester.pump();
    expect(moves, 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(moves, 2);
    f.stop();
    await tester.pump();
    expect(stops, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(moves, 2);
    f.dispose();
  });
  testWidgets('five second maximum stops a continuously held gesture', (
    tester,
  ) async {
    int stops = 0;
    final f = FlagSession(
      move: (_, _, _) async => success(),
      stop: (_, _) async {
        stops++;
        return success();
      },
      canMove: () => true,
      newLease: () => 'lease',
    );
    f.start(FlagDirection.lowering);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(f.active, false);
    expect(stops, 1);
    f.dispose();
  });
}
