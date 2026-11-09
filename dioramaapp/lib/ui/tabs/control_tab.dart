import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/diorama_provider.dart';
import '../../models/api_command.dart';
import '../../models/command_result.dart';
import '../widgets/control_tile.dart';

class ControlTab extends StatelessWidget {
  const ControlTab({super.key});
  Future<void> _run(
    BuildContext context,
    Future<ActionOutcome> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await action();
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(outcome.message)));
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not send the command. Refresh and try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DioramaProvider>();
    final s = p.state;
    final connected = p.canControl;
    final lights = connected && !p.isAutoMode;
    final remote = connected && (p.isDemoMode || s.slaveOnline);
    final audio = p.isDemoMode || (s.device?.audio.ready ?? false);
    final reason = !connected
        ? 'Connect and refresh the device first.'
        : p.isAutoMode
        ? 'Switch to manual mode for lighting.'
        : 'The slave is offline.';
    Widget tile(
      String title,
      String icon,
      bool on,
      bool allowed,
      Future<ActionOutcome> Function() action, {
      String? pendingKey,
      bool unknown = false,
      String? lockReason,
    }) {
      final pending = s.pending.contains(pendingKey);
      return ControlTile(
        title: title,
        icon: icon,
        isOn: on,
        isLocked: !allowed || pending,
        onTap: () => _run(context, action),
        lockedMessage: pending
            ? 'A command is still pending.'
            : lockReason ?? reason,
        statusLabel: unknown
            ? 'UNKNOWN'
            : pending
            ? 'PENDING'
            : null,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            !connected
                ? 'Device state is stale. Reconnect to control it.'
                : p.isAutoMode
                ? 'Automatic: sensors control lighting.'
                : 'Manual: app and physical buttons control lighting.',
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.12,
            children: [
              tile(
                'Fountain lights',
                '⛲',
                s.isFountainOn,
                lights,
                () => p.setLight(LightTarget.fountain, !s.isFountainOn),
                pendingKey: 'light_fountain',
                unknown: !connected,
              ),
              tile(
                'Streetlights',
                '💡',
                s.isTreeLightsOn,
                lights,
                () => p.setLight(LightTarget.rgb, !s.isTreeLightsOn),
                pendingKey: 'light_rgb',
                unknown: !connected,
              ),
              tile(
                'Building lights',
                '🏛',
                s.isBuildingLightsOn,
                lights,
                () => p.setLight(LightTarget.building, !s.isBuildingLightsOn),
                pendingKey: 'light_building',
                unknown: !connected,
              ),
              tile(
                'Sound + Fountain',
                '🔊',
                p.combinedActive,
                remote && (audio || p.combinedActive),
                () => p.setCombined(!p.combinedActive),
                pendingKey: 'audio_pump1',
                unknown: !remote,
                lockReason: !connected
                    ? 'Connect and refresh the device first.'
                    : !remote
                    ? 'The slave is offline.'
                    : 'The diorama audio player is not ready.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
