// lib/models/music_track.dart

class MusicTrack {
  final String title;
  final String subtitle;
  final int durationSeconds;

  /// The command sent to the ESP32 to play this specific track.
  /// Example: 'audio_play_1' or 'audio_play_history'
  final String triggerCommand;

  const MusicTrack({
    required this.title,
    required this.subtitle,
    required this.durationSeconds,
    required this.triggerCommand,
  });

  /// Helper method to format the duration into a mm:ss string for the UI
  int get trackId => int.parse(triggerCommand.substring(11));
  String get formattedDuration {
    if (durationSeconds == 0) return '--:--';
    final minutes = (durationSeconds / 60).floor();
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
