import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/diorama_provider.dart';
import '../../models/api_command.dart';
import '../../core/app_colors.dart';
import '../widgets/flag_visual.dart';

class FlagTab extends StatefulWidget {
  const FlagTab({super.key});
  @override
  State<FlagTab> createState() => _FlagTabState();
}

class _FlagTabState extends State<FlagTab> {
  DioramaProvider? _provider;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<DioramaProvider>();
  }

  @override
  void dispose() {
    _provider?.leaveFlagTab();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DioramaProvider>();
    final status = p.state.device;
    Widget control(String text, FlagDirection dir, IconData icon) {
      return Expanded(
        child: Semantics(
          button: true,
          label: text,
          enabled: p.canMove,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: p.canMove ? (_) => p.flag.start(dir) : null,
            onTapUp: (_) => p.flag.stop(),
            onTapCancel: p.flag.stop,
            child: Container(
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.canMove
                    ? AppColors.forestGreen
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lineBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 6),
                  Flexible(child: Text(text)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: FlagVisual(
              flagPercent: p.isDemoMode ? p.state.flagHeightPercent : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.isDemoMode
                ? 'Demo movement'
                : !p.canControl
                ? 'Device offline'
                : p.isAutoMode
                ? 'Switch to manual mode to move the flag'
                : !p.state.slaveOnline
                ? 'Slave offline'
                : status?.motorOwner == 'joystick'
                ? 'Joystick is controlling the flag'
                : 'Flag ${status?.motorDirection ?? 'stopped'}',
          ),
          const SizedBox(height: 8),
          const Text(
            'Hold to move. Release to stop. Maximum 5 seconds per hold.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              control(
                'Hold to raise',
                FlagDirection.raising,
                Icons.arrow_upward,
              ),
              const SizedBox(width: 12),
              control(
                'Hold to lower',
                FlagDirection.lowering,
                Icons.arrow_downward,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
