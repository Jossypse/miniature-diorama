import 'dart:async';

import '../models/api_command.dart';
import '../models/command_result.dart';
import '../models/esp_state.dart';
import 'wifi_client.dart';

enum ConnectionMode { wifi, bluetooth }

class ConnectionManager {
  final EspState state;
  final WifiClient client;
  Timer? _timer;
  Future<void>? _flight;
  int _flightEpoch = 0, _epoch = 0, _failures = 0;
  bool _disposed = false, _foreground = true;
  final Map<String, String> _busy = {};
  ConnectionManager(this.state, {WifiClient? client})
    : client = client ?? WifiClient();
  ConnectionMode get activeMode => ConnectionMode.wifi;
  void setMode(ConnectionMode mode) {
    if (mode != ConnectionMode.wifi) {
      throw UnsupportedError('Bluetooth is not supported by this firmware');
    }
  }

  bool get foreground => _foreground;
  Future<void> connectWifi() async {
    if (_disposed) return;
    _epoch++;
    _foreground = true;
    state.foreground = true;
    state.stale('Connecting', offline: true);
    _failures = 0;
    startSensorPolling();
    await refresh();
  }

  Future<void> checkConnection() => connectWifi();
  void startSensorPolling() {
    _timer?.cancel();
    if (!_disposed && _foreground) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(refresh()),
      );
    }
  }

  void stopSensorPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (_disposed || !_foreground) return;
    final epoch = _epoch;
    if (_flight != null) {
      final same = _flightEpoch == epoch;
      await _flight;
      if (!same && !_disposed && epoch == _epoch && _foreground) {
        await refresh();
      }
      return;
    }
    _flightEpoch = epoch;
    final future = _fetch(epoch);
    _flight = future;
    try {
      await future;
    } finally {
      if (identical(_flight, future)) _flight = null;
    }
  }

  Future<void> _fetch(int epoch) async {
    final timer = Stopwatch()..start();
    try {
      final status = await client.fetchStatus();
      if (_disposed || !_foreground || epoch != _epoch) return;
      if (state.device != null && state.device!.bootId != status.bootId) {
        _epoch++;
        _busy.clear();
        state.pending.clear();
      }
      _failures = 0;
      state.pingMs = timer.elapsedMilliseconds;
      state.applyDeviceStatus(status);
    } catch (e) {
      if (_disposed || !_foreground || epoch != _epoch) return;
      _failures++;
      state.stale(e.toString(), offline: _failures >= 2);
    }
  }

  void setForeground(bool value) {
    if (_disposed || _foreground == value) return;
    _foreground = value;
    _epoch++;
    state.foreground = value;
    _busy.clear();
    state.pending.clear();
    if (!value) {
      stopSensorPolling();
      state.stale('App paused');
    } else {
      state.stale('Refreshing device');
      startSensorPolling();
      unawaited(refresh());
    }
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    _epoch++;
    _foreground = false;
    stopSensorPolling();
    _busy.clear();
    state.pending.clear();
    state.foreground = false;
    state.setConnection(connected: false, type: 'WIFI', ping: 0, ip: '--');
  }

  String _key(ApiCommand c) {
    if (c.action.startsWith('flag.')) return c.action;
    if (c.action.startsWith('audio.') ||
        c.action == 'combined.set' ||
        c.action == 'relay.set' && c.args['relay'] == 1) {
      return 'audio_pump1';
    }
    if (c.action == 'light.set') return 'light_${c.args['target']}';
    return c.action;
  }

  Future<ActionOutcome> execute(ApiCommand c) async {
    final stop = c.action == 'flag.stop';
    if (_disposed || (!state.canControl && !stop) || state.device == null) {
      return const ActionOutcome(
        failure: 'Connect and refresh the device first',
      );
    }
    final epoch = _epoch;
    final key = _key(c);
    final motion = c.action.startsWith('flag.');
    if (!motion && _busy.containsKey(key)) {
      return const ActionOutcome(
        failure: 'A command for this control is still pending',
      );
    }
    if (!motion) {
      _busy[key] = c.id;
      state.pending.add(key);
      state.changed();
    }
    try {
      var r = await client.submit(c);
      if (_disposed || epoch != _epoch) {
        return const ActionOutcome(unconfirmed: true);
      }
      final wait = Stopwatch()..start();
      while (r.status == 'pending' && wait.elapsedMilliseconds < 2500) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (_disposed || epoch != _epoch) {
          return const ActionOutcome(unconfirmed: true);
        }
        final remaining = 2500 - wait.elapsedMilliseconds;
        if (remaining <= 0) break;
        r = await client
            .fetchResult(c.id)
            .timeout(Duration(milliseconds: remaining));
        if (r.bootId != c.bootId) {
          return const ActionOutcome(
            unconfirmed: true,
            failure: 'Device restarted',
          );
        }
      }
      if (_disposed || epoch != _epoch) {
        return const ActionOutcome(unconfirmed: true);
      }
      if (!motion) {
        await refresh();
        if (_disposed || epoch != _epoch) {
          return const ActionOutcome(unconfirmed: true);
        }
      }
      if (r.status == 'pending') {
        return ActionOutcome(result: r, unconfirmed: true);
      }
      return ActionOutcome(
        result: r,
        failure: r.status == 'failed' ? r.reason : null,
      );
    } catch (e) {
      if (!_disposed && epoch == _epoch && !motion) unawaited(refresh());
      if (e is ApiException && e.status >= 400 && e.status != 404) {
        return ActionOutcome(failure: e.code);
      }
      return const ActionOutcome(unconfirmed: true);
    } finally {
      if (!_disposed && _busy[key] == c.id) {
        _busy.remove(key);
        state.pending.remove(key);
        state.changed();
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    stopSensorPolling();
    client.dispose();
  }
}
