// lib/ui/widgets/flag_visual.dart

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class FlagVisual extends StatefulWidget {
  final int? flagPercent;

  const FlagVisual({super.key, required this.flagPercent});

  @override
  State<FlagVisual> createState() => _FlagVisualState();
}

class _FlagVisualState extends State<FlagVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // Animation controller to simulate the flag waving in the wind
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B0F12), Color(0xFF0D2A1D)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Percentage Text Indicator
            Positioned(
              top: 10,
              right: 14,
              child: Text(
                widget.flagPercent == null
                    ? 'Position unavailable'
                    : '${widget.flagPercent}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: AppColors.cream,
                ),
              ),
            ),

            // The Gold Flagpole
            Positioned(
              top: 14,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gold, Color(0xFFA77D1F)],
                  ),
                ),
              ),
            ),

            // The Moving Flag
            Builder(
              builder: (context) {
                // Calculate available vertical travel space
                final double travelDistance = constraints.maxHeight - 52 - 20;

                // Keep the flag percentage within 0–100
                final int safePercent = (widget.flagPercent ?? 50).clamp(
                  0,
                  100,
                );

                final double bottomPosition =
                    10 + (travelDistance * (safePercent / 100));

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.linear,
                  bottom: bottomPosition,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const SizedBox(width: 89), _buildWavingFlag()],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWavingFlag() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        // Calculate waving animation values
        final double skewY = (_waveController.value * 0.08) - 0.04;

        final double scaleX = 1.0 - (_waveController.value * 0.07);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..scaleByDouble(scaleX, 1.0, 1.0, 1.0)
            ..setEntry(1, 0, skewY),
          alignment: Alignment.centerLeft,
          child: Container(
            width: 84,
            height: 52,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0038A8),
                  Color(0xFF0038A8),
                  Color(0xFFCE1126),
                  Color(0xFFCE1126),
                ],
                stops: [0.0, 0.5, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // White Triangle
                ClipPath(
                  clipper: _TriangleClipper(),
                  child: Container(width: 42, height: 52, color: Colors.white),
                ),

                // Sun
                Positioned(
                  left: 12,
                  top: 21,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCD116),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // First Star
                Positioned(
                  left: 3,
                  top: 6,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCD116),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Second Star
                Positioned(
                  left: 3,
                  bottom: 6,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCD116),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Third Star
                Positioned(
                  left: 25,
                  top: 24,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCD116),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Philippine Flag White Triangle Clipper
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
