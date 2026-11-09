// lib/ui/widgets/animated_vinyl.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AnimatedVinyl extends StatefulWidget {
  final bool isPlaying;

  const AnimatedVinyl({
    super.key,
    required this.isPlaying,
  });

  @override
  State<AnimatedVinyl> createState() => _AnimatedVinylState();
}

class _AnimatedVinylState extends State<AnimatedVinyl> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedVinyl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF111111),
              border: Border.all(color: AppColors.lineBorder, width: 2),
              // Simulating vinyl grooves with a radial gradient
              gradient: const RadialGradient(
                colors: [Color(0xFF111111), Color(0xFF1D1212), Color(0xFF111111)],
                stops: [0.8, 0.9, 1.0],
              ),
            ),
            child: Center(
              // Center Label
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
                // Spindle hole
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.bgDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}