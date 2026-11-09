import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/music_track.dart';
import '../models/command_result.dart';
import 'diorama_provider.dart';

class MusicProvider extends ChangeNotifier {
  DioramaProvider? _device;
  List<MusicTrack> _library = [];
  final List<MusicTrack> _queue = [];
  String? _boot;
  int? _completion;
  bool _eligible = false,
      _advancing = false,
      _advancePending = false,
      _disposed = false;
  int _session = 0;
  String? queueError;
  List<MusicTrack> get library => List.unmodifiable(_library);
  List<MusicTrack> get queue => List.unmodifiable(_queue);
  bool get canPlay =>
      _device?.canControl == true &&
      (_device!.isDemoMode || _device!.state.device?.audio.ready == true);
  bool get busy => _device?.state.pending.contains('audio_pump1') ?? false;
  String get phase => _device?.isDemoMode == true
      ? _device!.demoAudioPhase
      : _device?.state.device?.audio.state ?? 'stopped';
  bool get isPlaying => phase == 'playing';
  int get volume => _device?.state.volume ?? 83;
  MusicTrack? get currentTrack {
    final id = _device?.isDemoMode == true
        ? int.tryParse(_device!.state.selectedTrack)
        : _device?.state.device?.audio.trackId;
    for (final t in _library) {
      if (t.trackId == id) return t;
    }
    return null;
  }

  void bind(DioramaProvider device) {
    if (identical(device, _device)) return;
    _device?.removeListener(_sync);
    _device = device;
    device.addListener(_sync);
    _sync(notify: false);
  }

  void _sync({bool notify = true}) {
    final p = _device!;
    final status = p.state.device;
    _library = p.isDemoMode
        ? List.generate(Constants.trackList.length, (i) {
            final t = Constants.trackList[i];
            return MusicTrack(
              title: t['title'] as String,
              subtitle: 'Demo simulation',
              durationSeconds: t['duration'] as int,
              triggerCommand: 'audio_play_${i + 1}',
            );
          })
        : (status?.tracks
                  .map(
                    (t) => MusicTrack(
                      title: t.title,
                      subtitle: 'Device speaker',
                      durationSeconds: 0,
                      triggerCommand: 'audio_play_${t.id}',
                    ),
                  )
                  .toList() ??
              []);
    final boot = p.isDemoMode ? 'demo' : status?.bootId;
    final sequence = p.isDemoMode
        ? p.demoAudioCompletion
        : status?.audio.completionSequence;
    final eligible = p.foreground && p.canControl;
    if (!eligible || boot != _boot) {
      _advancePending = false;
      _session++;
    }
    if (eligible &&
        _eligible &&
        boot == _boot &&
        _completion != null &&
        sequence != null &&
        sequence != _completion) {
      _advancePending = true;
    }
    _boot = boot;
    _completion = sequence;
    _eligible = eligible;
    if (_advancePending &&
        eligible &&
        canPlay &&
        !busy &&
        !_advancing &&
        queueError == null &&
        _queue.isNotEmpty) {
      _advancing = true;
      _advancePending = false;
      final session = _session;
      scheduleMicrotask(() => _advance(session));
    }
    if (notify) notifyListeners();
  }

  Future<void> _advance(int session) async {
    try {
      if (_disposed ||
          session != _session ||
          !canPlay ||
          busy ||
          _queue.isEmpty) {
        return;
      }
      final next = _queue.first;
      final result = await _dispatch(next);
      if (_disposed || session != _session) return;
      if (result.applied) {
        if (_queue.isNotEmpty && identical(_queue.first, next)) {
          _queue.removeAt(0);
        }
      } else {
        queueError =
            'Queue paused: ${result.message}. Select a track to continue.';
      }
    } catch (_) {
      if (!_disposed && session == _session) {
        queueError = 'Queue paused. Select a track to continue.';
      }
    } finally {
      _advancing = false;
      if (!_disposed) notifyListeners();
    }
  }

  void addToQueue(MusicTrack t) {
    if (!_library.any((item) => item.trackId == t.trackId)) return;
    _queue.add(t);
    notifyListeners();
  }

  void removeFromQueue(int i) {
    if (i >= 0 && i < _queue.length) {
      _queue.removeAt(i);
      notifyListeners();
    }
  }

  Future<ActionOutcome> _dispatch(MusicTrack t) async {
    if (!canPlay || !_library.any((item) => item.trackId == t.trackId)) {
      return const ActionOutcome(failure: 'Track unavailable');
    }
    return _device!.playTrackId(t.trackId);
  }

  Future<ActionOutcome> playTrack(MusicTrack t) {
    queueError = null;
    _advancePending = false;
    return _dispatch(t);
  }

  Future<ActionOutcome> pause() => _device!.pauseAudio();
  Future<ActionOutcome> resume() => _device!.resumeAudio();
  Future<ActionOutcome> stop() {
    _advancePending = false;
    return _device!.stopAudio();
  }

  Future<ActionOutcome> setVolume(int v) => _device!.setVolume(v);
  @override
  void dispose() {
    _disposed = true;
    _session++;
    _device?.removeListener(_sync);
    super.dispose();
  }
}
