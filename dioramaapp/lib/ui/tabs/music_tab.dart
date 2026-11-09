// lib/ui/tabs/music_tab.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/music_provider.dart';
import '../../providers/diorama_provider.dart';
import '../../models/command_result.dart';
import '../../models/music_track.dart';
import '../../core/app_colors.dart';

class MusicTab extends StatefulWidget {
  const MusicTab({super.key});

  @override
  State<MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends State<MusicTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _vinylController;
  int? _volumeDraft;
  void _explainUnavailable(MusicProvider music) {
    final device = context.read<DioramaProvider>();
    final message = music.busy
        ? 'An audio command is still pending. Please wait.'
        : !device.canControl
        ? 'Connect to the diorama and refresh its status first.'
        : music.phase == 'error'
        ? 'The app is connected, but the device reports an audio error.'
        : 'The diorama audio player is not ready.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<ActionOutcome> action) async {
    final r = await action;
    if (mounted && !r.applied) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.message)));
    }
  }

  void _toggle(MusicProvider m) {
    if (m.phase == 'playing') {
      _run(m.pause());
    } else if (m.phase == 'paused') {
      _run(m.resume());
    } else if (m.library.isNotEmpty) {
      _run(m.playTrack(m.currentTrack ?? m.library.first));
    }
  }

  Future<void> _skip(MusicProvider m, int direction) async {
    if (direction > 0 && m.queue.isNotEmpty) {
      final next = m.queue.first;
      final result = await m.playTrack(next);
      if (result.applied &&
          m.queue.isNotEmpty &&
          identical(m.queue.first, next)) {
        m.removeFromQueue(0);
      }
      if (mounted && !result.applied) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message)));
      }
      return;
    }
    if (m.library.isEmpty) return;
    final index = m.library.indexWhere(
      (t) => t.trackId == m.currentTrack?.trackId,
    );
    final MusicTrack next =
        m.library[(index < 0 ? 0 : (index + direction) % m.library.length)];
    await _run(m.playTrack(next));
  }

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final dioramaProvider = Provider.of<DioramaProvider>(
      context,
      listen: false,
    );

    final enabled = musicProvider.canPlay && !musicProvider.busy;
    if (musicProvider.isPlaying && !_vinylController.isAnimating) {
      _vinylController.repeat();
    } else if (!musicProvider.isPlaying) {
      _vinylController.stop();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            children: [
              // 1. Now Playing Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lineBorder),
                ),
                child: Row(
                  children: [
                    // Spinning Vinyl
                    AnimatedBuilder(
                      animation: _vinylController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _vinylController.value * 2 * math.pi,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.lineBorder,
                                width: 2,
                              ),
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF111111),
                                  Color(0xFF292020),
                                  Color(0xFF111111),
                                ],
                                stops: [0.6, 0.8, 1],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppColors.red, AppColors.green],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    // Title and EQ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            musicProvider.currentTrack?.title ??
                                'Nothing selected',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Simple CSS-like EQ visualization
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(4, (index) {
                              // Simple math to make bars bounce differently based on the vinyl controller
                              double height = musicProvider.isPlaying
                                  ? 4 +
                                        (math.sin(
                                                  (_vinylController.value *
                                                          math.pi *
                                                          2) +
                                                      index,
                                                ) +
                                                1) *
                                            7
                                  : 4;
                              return Container(
                                margin: const EdgeInsets.only(right: 3),
                                width: 4,
                                height: height,
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  height: 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      curve: Curves.linear,
                      width: 0, // Device does not report elapsed position.
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [AppColors.red, AppColors.green],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Text(
                musicProvider.canPlay
                    ? musicProvider.phase
                    : 'Speaker unavailable',
                style: const TextStyle(fontSize: 12, color: AppColors.cream),
              ),
              // 3. Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous track',
                    iconSize: 32,
                    color: Colors.white,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: enabled ? () => _skip(musicProvider, -1) : null,
                  ),
                  const SizedBox(width: 18),
                  Semantics(
                    button: true,
                    label: musicProvider.isPlaying ? 'Pause' : 'Play',
                    enabled: enabled,
                    child: GestureDetector(
                      onTap: enabled ? () => _toggle(musicProvider) : null,
                      child: Opacity(
                        opacity: enabled ? 1 : 0.4,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.green, AppColors.forestGreen],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.45),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            musicProvider.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  IconButton(
                    tooltip: 'Next track',
                    iconSize: 32,
                    color: Colors.white,
                    icon: const Icon(Icons.skip_next),
                    onPressed: enabled ? () => _skip(musicProvider, 1) : null,
                  ),
                  IconButton(
                    tooltip: 'Stop',
                    color: Colors.white,
                    icon: const Icon(Icons.stop),
                    onPressed: enabled
                        ? () => _run(musicProvider.stop())
                        : null,
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.volume_up, size: 18, color: AppColors.cream),
                  Expanded(
                    child: Slider(
                      value: (_volumeDraft ?? musicProvider.volume).toDouble(),
                      max: 100,
                      onChanged: enabled
                          ? (v) => setState(() => _volumeDraft = v.round())
                          : null,
                      onChangeEnd: enabled
                          ? (v) async {
                              await _run(musicProvider.setVolume(v.round()));
                              if (mounted) setState(() => _volumeDraft = null);
                            }
                          : null,
                    ),
                  ),
                  Text(
                    '${_volumeDraft ?? musicProvider.volume}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cream,
                    ),
                  ),
                ],
              ),

              // 4. Output Selector
              Container(
                margin: const EdgeInsets.only(top: 14, bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildOutputButton(
                      title: '📱 Phone',
                      isActive: false,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Phone playback is unavailable. Audio plays on the diorama.',
                          ),
                        ),
                      ),
                      available: false,
                    ),
                    _buildOutputButton(
                      title: '🏛️ Diorama',
                      isActive: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              if (musicProvider.queueError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    musicProvider.queueError!,
                    style: const TextStyle(color: AppColors.gold, fontSize: 12),
                  ),
                ),
              // 5. Dual Tile SD Card Playlists
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lineBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SD CARD PLAYLISTS   TAP TO QUEUE',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        // Added a scroll view to prevent overflow on small/landscape screens
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildPlaylistTile(
                                title: 'PLAY AUDIO HISTORY',
                                subtitle: dioramaProvider.isDemoMode
                                    ? 'Daet Capitol Narration & Soundtrack sequence'
                                    : 'SD card ? Track 1',
                                icon: '📜',
                                command: 'audio_play_history',
                                dioramaProvider: dioramaProvider,
                                musicProvider: musicProvider,
                              ),
                              const SizedBox(height: 12),
                              _buildPlaylistTile(
                                title: 'PLAY XMAS AUDIO',
                                subtitle: dioramaProvider.isDemoMode
                                    ? 'Holiday music sequence'
                                    : 'SD card ? Track 2',
                                icon: '🎄',
                                command: 'audio_play_christmas',
                                dioramaProvider: dioramaProvider,
                                musicProvider: musicProvider,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
          return constraints.maxHeight < 560
              ? SingleChildScrollView(
                  child: SizedBox(height: 680, child: content),
                )
              : content;
        },
      ),
    );
  }

  Widget _buildOutputButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    bool available = true,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.red, AppColors.forestGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.3),
                      blurRadius: 18,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: !available
                  ? Colors.white38
                  : isActive
                  ? Colors.white
                  : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistTile({
    required String title,
    required String subtitle,
    required String icon,
    required String command,
    required DioramaProvider dioramaProvider,
    required MusicProvider musicProvider,
  }) {
    final history = command == 'audio_play_history';
    final trackId = history ? 1 : 2;
    final playingIds = dioramaProvider.isDemoMode
        ? (history ? [2, 5, 1] : [3, 6, 4])
        : [trackId];
    final isPlaying =
        musicProvider.isPlaying &&
        playingIds.contains(musicProvider.currentTrack?.trackId);
    final enabled = musicProvider.canPlay && !musicProvider.busy;
    return GestureDetector(
      onTap: enabled
          ? () async {
              if (dioramaProvider.isDemoMode) {
                final indices = history ? [1, 4, 0] : [2, 5, 3];
                final tracks = indices
                    .where((i) => i < musicProvider.library.length)
                    .map((i) => musicProvider.library[i])
                    .toList();
                if (tracks.isNotEmpty) {
                  for (var i = musicProvider.queue.length - 1; i >= 0; i--) {
                    musicProvider.removeFromQueue(i);
                  }
                  await _run(musicProvider.playTrack(tracks.first));
                  for (final t in tracks.skip(1)) {
                    musicProvider.addToQueue(t);
                  }
                }
              } else {
                final matches = musicProvider.library.where(
                  (t) => t.trackId == trackId,
                );
                if (matches.isNotEmpty) {
                  await _run(musicProvider.playTrack(matches.first));
                }
              }
            }
          : () => _explainUnavailable(musicProvider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.green.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? AppColors.green : AppColors.lineBorder,
            width: isPlaying ? 1.5 : 1.0,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lineBorder),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPlaying
                          ? const Color(0xFF6DFFA3)
                          : AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC9A9A0),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPlaying ? AppColors.green : AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPlaying ? AppColors.green : AppColors.lineBorder,
                ),
              ),
              child: Icon(
                isPlaying ? Icons.graphic_eq : Icons.play_arrow,
                color: isPlaying ? AppColors.bgDark : AppColors.gold,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
