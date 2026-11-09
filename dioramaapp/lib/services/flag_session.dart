import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/api_command.dart';
import '../models/command_result.dart';

typedef FlagMove = Future<ActionOutcome> Function(String, int, FlagDirection);
typedef FlagStop = Future<ActionOutcome> Function(String, int);

class FlagSession extends ChangeNotifier {
  final FlagMove move;
  final FlagStop sendStop;
  final bool Function() canMove;
  final String Function() newLease;
  final int Function()? seedSequence;
  Timer? _renew, _cap;
  bool _active = false, _sending = false, _disposed = false, _seeded = false;
  int _sequence = 0, _epoch = 0;
  String _lease = '';
  FlagDirection _direction = FlagDirection.raising;
  FlagSession({
    required this.move,
    required FlagStop stop,
    required this.canMove,
    String Function()? newLease,
    this.seedSequence,
  }) : sendStop = stop,
       newLease =
           newLease ?? (() => 'g_${Random.secure().nextInt(0x7fffffff)}');
  bool get active => _active;
  void resetSequence(int sequence) {
    _renew?.cancel();
    _cap?.cancel();
    _active = false;
    _sending = false;
    _epoch++;
    _sequence = sequence;
    _seeded = true;
    if (!_disposed) notifyListeners();
  }

  void start(FlagDirection direction) {
    if (_disposed || _active || !canMove()) return;
    _epoch++;
    _active = true;
    _sending = false;
    _lease = newLease();
    _direction = direction;
    final seed = seedSequence?.call() ?? 0;
    final delta = (seed - _sequence) & 0xffffffff;
    if (!_seeded || delta != 0 && delta < 0x80000000) _sequence = seed;
    _seeded = true;
    unawaited(_send(_epoch));
    _renew = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!canMove()) {
        stop();
        return;
      }
      if (!_sending) unawaited(_send(_epoch));
    });
    _cap = Timer(const Duration(seconds: 5), stop);
    notifyListeners();
  }

  Future<void> _send(int epoch) async {
    if (!_active || _disposed || _sending) return;
    _sending = true;
    _sequence = (_sequence + 1) & 0xffffffff;
    try {
      final outcome = await move(_lease, _sequence, _direction);
      if (!_disposed && _active && epoch == _epoch && !outcome.applied) stop();
    } catch (_) {
      if (!_disposed && epoch == _epoch) stop();
    } finally {
      if (epoch == _epoch) _sending = false;
    }
  }

  void stop() {
    _renew?.cancel();
    _cap?.cancel();
    if (!_active) return;
    _active = false;
    _epoch++;
    _sequence = (_sequence + 1) & 0xffffffff;
    _sending = false;
    unawaited(
      sendStop(
        _lease,
        _sequence,
      ).catchError((Object _) => const ActionOutcome(unconfirmed: true)),
    );
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    super.dispose();
  }
}
