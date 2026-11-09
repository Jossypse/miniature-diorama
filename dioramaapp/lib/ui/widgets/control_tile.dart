// lib/ui/widgets/control_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';

class ControlTile extends StatelessWidget {
  final String icon;
  final String title;
  final bool isOn;
  final bool isLocked;
  final VoidCallback onTap;
  final String? statusLabel;
  final String lockedMessage;

  const ControlTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isOn,
    required this.isLocked,
    required this.onTap,
    this.statusLabel,
    this.lockedMessage = 'Switch to manual mode to use this control.',
  });

  // Luminance-based grayscale. Alpha row is untouched, so transparent
  // pixels stay transparent (unlike ColorFilter.mode + BlendMode.saturation,
  // which paints the whole layer gray).
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final Widget iconText = Text(icon, style: const TextStyle(fontSize: 34));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isLocked) {
          HapticFeedback.lightImpact();
          onTap();
        } else {
          // Provide slight feedback that the tile is locked (Auto mode)
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lockedMessage),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: RepaintBoundary(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isLocked ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: isOn
                  ? AppColors.green.withValues(alpha: 0.15)
                  : AppColors.cardBackground,
              border: Border.all(
                color: isOn
                    ? AppColors.green
                    : AppColors.red.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: isOn
                  ? [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.35),
                        blurRadius: 26,
                        spreadRadius: -5,
                      ),
                    ]
                  : [],
              gradient: isOn
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.green.withValues(alpha: 0.22),
                        AppColors.forestGreen.withValues(alpha: 0.15),
                      ],
                    )
                  : null,
            ),
            // FittedBox scales content down if it would overflow
            // (e.g. the two-line "SOUND + FOUNTAIN" title).
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon scaling + grayscale when OFF
                    AnimatedScale(
                      scale: isOn ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      child: isOn
                          ? iconText
                          : ColorFiltered(
                              colorFilter: _grayscale,
                              child: iconText,
                            ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status Text
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: isOn
                            ? const Color(0xFF6DFFA3)
                            : const Color(0xFFFF9A9A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      child: Text(statusLabel ?? (isOn ? 'ON' : 'OFF')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
