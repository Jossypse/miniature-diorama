// lib/ui/tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/diorama_provider.dart';
import '../../core/app_colors.dart';
import '../widgets/diorama_svg.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DioramaProvider>(context);
    final state = provider.state;
    final fresh = provider.isDemoMode || state.sensorsFresh;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Diorama Visualizer Card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lineBorder),
            ),
            child: DioramaVisualizer(
              isFountainOn: state.isFountainOn,
              fountainColor: provider.isDemoMode
                  ? state.currentColor
                  : state.device?.fountainColor ?? 'NONE',
              isBuildingLightsOn: state.isBuildingLightsOn,
              isStreetlightsOn: state.isTreeLightsOn,
              flagPercent: provider.isDemoMode ? state.flagHeightPercent : null,
            ),
          ),
          const SizedBox(height: 16),

          // 2. Auto / Manual Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildModeButton(
                  title: '⚙️ AUTO',
                  isActive: provider.isAutoMode,
                  onTap: () => _mode(context, provider, true),
                ),
                _buildModeButton(
                  title: '🖐️ MANUAL',
                  isActive: !provider.isAutoMode,
                  onTap: () => _mode(context, provider, false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Sensor Grid
          Row(
            children: [
              _buildSensorTile(
                icon: '', // Handled by dynamic color circle
                label: 'Color',
                value: !fresh
                    ? 'unknown'
                    : state.currentColor == 'NONE' || state.currentColor == '--'
                    ? '–'
                    : state.currentColor,
                isActive:
                    fresh &&
                    state.currentColor != 'NONE' &&
                    state.currentColor != '--',
                dynamicColor: _parseColorStr(
                  fresh ? state.currentColor : 'NONE',
                ),
              ),
              const SizedBox(width: 8),
              _buildSensorTile(
                icon: '👣',
                label: 'IR',
                value: !provider.isDemoMode && !state.sensorsFresh
                    ? 'unknown'
                    : state.irMotionDetected
                    ? 'visitor!'
                    : 'clear',
                isActive: fresh && state.irMotionDetected,
              ),
              const SizedBox(width: 8),
              _buildSensorTile(
                icon: '🎤',
                label: 'Sound',
                value: !provider.isDemoMode && !state.sensorsFresh
                    ? 'unknown'
                    : state.soundDetected
                    ? 'loud'
                    : 'quiet',
                isActive: fresh && state.soundDetected,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Activity Log Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVITY LOG · LCD MIRROR',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  state.logs.isNotEmpty
                      ? state.logs.map((s) => '> $s').join('\n')
                      : '> Waiting for device logs...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFFFD0C0),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _mode(
    BuildContext context,
    DioramaProvider p,
    bool automatic,
  ) async {
    if (!p.canControl || p.state.pending.contains('mode.set')) return;
    try {
      await p.setAppMode(automatic);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _buildModeButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
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
              color: isActive ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorTile({
    required String icon,
    required String label,
    required String value,
    required bool isActive,
    Color? dynamicColor,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.green : AppColors.lineBorder,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            if (dynamicColor != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dynamicColor,
                  border: Border.all(color: AppColors.lineBorder, width: 2),
                  boxShadow: isActive
                      ? [BoxShadow(color: dynamicColor, blurRadius: 14)]
                      : [],
                ),
              )
            else
              Text(icon, style: const TextStyle(fontSize: 20, height: 1.1)),

            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.cream),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.cream,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColorStr(String colorStr) {
    switch (colorStr.toUpperCase()) {
      case 'RED':
        return AppColors.red;
      case 'GREEN':
        return AppColors.green;
      case 'BLUE':
        return Colors.blueAccent;
      case 'YELLOW':
        return AppColors.gold;
      case 'WHITE':
        return Colors.white;
      default:
        return const Color(0xFF333333); // Dark grey for NONE/invalid
    }
  }
}
