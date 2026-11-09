import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/esp_state.dart';
import '../core/constants.dart';
import '../models/api_command.dart';
import '../models/command_result.dart';
import '../services/connection_manager.dart';
import '../services/wifi_client.dart';
import '../services/flag_session.dart';

class DioramaProvider extends ChangeNotifier with WidgetsBindingObserver {
  final EspState state = EspState();
  late final ConnectionManager connectionManager;
  late final FlagSession flag;
  bool _disposed = false,
      _foreground = true,
      _demoAuto = true,
      isDemoMode = false,
      _demoCombined = false;
  int _counter = 0, _demoDirection = 0, _demoRelays = 0;
  String demoAudioPhase = "stopped";
  int demoAudioCompletion = 0, _demoAudioTicks = 0, _demoPumpTicks = 0;
  String? _lastBoot;
  final String _prefix = List.generate(
    6,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  Timer? _demoTimer;
  final List<String> audioQueue = [];
  DioramaProvider({WifiClient? client}) {
    connectionManager = ConnectionManager(state, client: client);
    flag = FlagSession(
      move: (lease, sequence, direction) => _act('flag.move', {
        'leaseId': lease,
        'sequence': sequence,
        'direction': direction.name,
      }),
      stop: (lease, sequence) =>
          _act('flag.stop', {'leaseId': lease, 'sequence': sequence}),
      canMove: () => canMove,
      newLease: () => 'g_${_id()}',
      seedSequence: () => state.device?.motionSequence ?? 0,
    );
    flag.addListener(_flagChanged);
    state.addListener(_onStateChanged);
    WidgetsBinding.instance.addObserver(this);
  }
  bool get foreground => _foreground;
  bool get isAutoMode => isDemoMode ? _demoAuto : state.isAutoMode;
  bool get canControl =>
      isDemoMode ? !_disposed && _foreground : state.canControl;
  bool get canMove =>
      canControl &&
      !isAutoMode &&
      (isDemoMode ||
          state.slaveOnline &&
              state.sensorsFresh &&
              (state.device?.capabilities['flagApp'] ?? false));
  bool get combinedActive => isDemoMode
      ? _demoCombined
      : (state.device?.combinedState == 'active' ||
            state.device?.combinedState == 'starting');
  bool get pumpsKnown =>
      isDemoMode || state.canControl && (state.device?.relaysKnown ?? false);
  bool pumpOn(int n) => ((_demoOrRealRelays) & (1 << (n - 1))) != 0;
  int get _demoOrRealRelays =>
      isDemoMode ? _demoRelays : (state.device?.confirmedRelays ?? 0);
  String _id() => '${_prefix}_${++_counter}';
  void _flagChanged() {
    if (!_disposed) notifyListeners();
  }

  void _onStateChanged() {
    final boot = state.device?.bootId;
    if (boot != null && boot != _lastBoot) {
      flag.resetSequence(state.device!.motionSequence);
    } else if (flag.active &&
        (!canMove || state.device?.motorOwner == 'joystick')) {
      flag.stop();
    }
    _lastBoot = boot;
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (isDemoMode) disableDemoMode();
    _foreground = true;
    await connectionManager.connectWifi();
  }

  void setNetworkMode(ConnectionMode mode) => connectionManager.setMode(mode);
  Future<void> connectBluetooth(Object device) async =>
      throw UnsupportedError('Bluetooth is unavailable in this Wi-Fi release');
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setForeground(state == AppLifecycleState.resumed);
  }

  void setForeground(bool value) {
    if (_disposed || _foreground == value) return;
    if (!value) flag.stop();
    _foreground = value;
    if (!isDemoMode) connectionManager.setForeground(value);
    notifyListeners();
  }

  void leaveFlagTab() => flag.stop();
  Future<void> disconnect() async {
    flag.stop();
    await connectionManager.disconnect();
  }

  Future<ActionOutcome> _act(String action, Map<String, dynamic> args) async {
    if (_disposed) return const ActionOutcome(failure: 'App closed');
    if (isDemoMode) {
      switch (action) {
        case 'light.set':
          final target = args['target'];
          final on = args['enabled'] == true;
          state.applyCommand(
            '${target == 'building'
                ? 'lights'
                : target == 'rgb'
                ? 'tree_lights'
                : 'fountain'}_${on ? 'on' : 'off'}',
          );
          break;
        case 'relay.set':
          final bit = 1 << ((args['relay'] as int) - 1);
          _demoRelays = args['enabled'] == true
              ? _demoRelays | bit
              : _demoRelays & ~bit;
          break;
        case 'combined.set':
          _demoCombined = args['enabled'] == true;
          state.isAudioPlaying = _demoCombined;
          demoAudioPhase = _demoCombined ? "playing" : "stopped";
          _demoAudioTicks = 0;
          state.selectedTrack = "1";
          _demoRelays = _demoCombined ? 1 : 0;
          _demoPumpTicks = 0;
          break;
        case 'audio.play':
          if (_demoCombined) {
            _demoCombined = false;
            _demoRelays = 0;
          }
          state.isAudioPlaying = true;
          demoAudioPhase = "playing";
          _demoAudioTicks = 0;
          state.selectedTrack = '${args['trackId']}';
          break;
        case 'audio.pause':
          state.isAudioPlaying = false;
          demoAudioPhase = 'paused';
          _demoCombined = false;
          _demoRelays = 0;
          break;
        case 'audio.stop':
          state.isAudioPlaying = false;
          demoAudioPhase = 'stopped';
          _demoAudioTicks = 0;
          _demoCombined = false;
          _demoRelays = 0;
          break;
        case 'audio.resume':
          state.isAudioPlaying = true;
          demoAudioPhase = 'playing';
          break;
        case 'audio.volume':
          state.volume = args['percent'] as int;
          break;
        case 'flag.move':
          _demoDirection = args['direction'] == 'raising' ? 1 : -1;
          break;
        case 'flag.stop':
          _demoDirection = 0;
          break;
      }
      state.changed();
      return ActionOutcome(
        result: CommandResult.fromJson({
          'apiVersion': 1,
          'bootId': '00000001',
          'id': _id(),
          'status': 'applied',
          'reason': null,
          'acceptedAtMs': 0,
          'finishedAtMs': 0,
        }),
      );
    }
    final boot = state.device?.bootId;
    if (boot == null) {
      return const ActionOutcome(failure: 'Connect to the device first');
    }
    return connectionManager.execute(
      ApiCommand(id: _id(), bootId: boot, action: action, args: args),
    );
  }

  Future<void> setAppMode(bool automatic) async {
    flag.stop();
    if (isDemoMode) {
      _demoAuto = automatic;
      state.isFountainOn = state.isBuildingLightsOn = state.isTreeLightsOn =
          false;
      state.changed();
      return;
    }
    final outcome = await _act('mode.set', {'automatic': automatic});
    if (!outcome.applied) throw StateError(outcome.message);
  }

  Future<ActionOutcome> setLight(LightTarget target, bool enabled) =>
      _act('light.set', {'target': target.name, 'enabled': enabled});
  Future<ActionOutcome> setRelay(int relay, bool enabled) =>
      _act('relay.set', {'relay': relay, 'enabled': enabled});
  Future<ActionOutcome> setCombined(bool enabled) =>
      _act('combined.set', {'enabled': enabled});
  Future<ActionOutcome> playTrackId(int id) =>
      _act('audio.play', {'trackId': id});
  Future<ActionOutcome> pauseAudio() => _act('audio.pause', {});
  Future<ActionOutcome> resumeAudio() => _act('audio.resume', {});
  Future<ActionOutcome> stopAudio() => _act('audio.stop', {});
  Future<ActionOutcome> setVolume(int percent) =>
      _act('audio.volume', {'percent': percent});
  Future<void> playTrack(String command) => sendCommand(command);
  Future<void> sendCommand(String action) async {
    if (action == 'flag_raise' || action == 'flag_lower') {
      flag.start(
        action == 'flag_raise' ? FlagDirection.raising : FlagDirection.lowering,
      );
      return;
    }
    if (action == 'flag_stop') {
      flag.stop();
      return;
    }
    ActionOutcome result;
    if (action.startsWith('fountain_')) {
      result = await setLight(LightTarget.fountain, action.endsWith('_on'));
    } else if (action.startsWith('tree_lights_')) {
      result = await setLight(LightTarget.rgb, action.endsWith('_on'));
    } else if (action.startsWith('lights_')) {
      result = await setLight(LightTarget.building, action.endsWith('_on'));
    } else if (action.startsWith('audio_play_')) {
      result = await playTrackId(int.tryParse(action.substring(11)) ?? 0);
    } else if (action == 'audio_pause') {
      result = await pauseAudio();
    } else if (action == 'audio_stop') {
      result = await stopAudio();
    } else if (action.startsWith('volume_set?level=')) {
      result = await setVolume(int.tryParse(action.substring(17)) ?? 0);
    } else {
      throw UnsupportedError('This feature is not available on the device');
    }
    if (!result.applied) throw StateError(result.message);
  }

  void enableDemoMode() {
    flag.stop();
    unawaited(connectionManager.disconnect());
    isDemoMode = true;
    _foreground = true;
    state.device = null;
    state.dataStale = false;
    state.foreground = true;
    state.setConnection(
      connected: true,
      type: 'DEMO',
      ip: 'offline-demo',
      ping: 0,
    );
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_disposed || !isDemoMode || !_foreground) return;
      if (_demoCombined && ++_demoPumpTicks >= 40) {
        _demoPumpTicks = 0;
        _demoRelays = _demoRelays == 1 ? 2 : 1;
        state.changed();
      }
      if (demoAudioPhase == 'playing') {
        _demoAudioTicks++;
        final index = (int.tryParse(state.selectedTrack) ?? 1) - 1;
        final duration =
            Constants.trackList[index.clamp(
                  0,
                  Constants.trackList.length - 1,
                )]['duration']
                as int;
        if (_demoAudioTicks >= duration * 10) {
          demoAudioPhase = 'stopped';
          state.isAudioPlaying = false;
          demoAudioCompletion++;
          _demoCombined = false;
          _demoRelays = 0;
          state.changed();
        }
      }
      if (_demoDirection != 0) {
        state.flagHeightPercent = (state.flagHeightPercent + _demoDirection)
            .clamp(0, 100);
        state.changed();
      }
    });
  }

  void disableDemoMode() {
    if (!isDemoMode) return;
    flag.stop();
    _demoTimer?.cancel();
    _demoDirection = 0;
    isDemoMode = false;
    state.device = null;
    state.setConnection(connected: false, type: 'WIFI', ip: '--', ping: 0);
  }

  void queueTrack(String command) {
    audioQueue.add(command);
    notifyListeners();
  }

  void removeFromQueue(int i) {
    if (i >= 0 && i < audioQueue.length) {
      audioQueue.removeAt(i);
      notifyListeners();
    }
  }

  Future<void> playNextInQueue() async {
    if (audioQueue.isNotEmpty) await sendCommand(audioQueue.removeAt(0));
  }

  @override
  void dispose() {
    if (_disposed) return;
    flag.stop();
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _demoTimer?.cancel();
    state.removeListener(_onStateChanged);
    flag.removeListener(_flagChanged);
    flag.dispose();
    connectionManager.dispose();
    state.dispose();
    super.dispose();
  }
}
