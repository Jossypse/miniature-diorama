// lib/ui/widgets/diorama_svg.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class DioramaVisualizer extends StatefulWidget {
  final bool isFountainOn;
  final String
  fountainColor; // 'RED', 'GREEN', 'BLUE', 'YELLOW', 'WHITE', 'NONE'
  final bool isBuildingLightsOn;
  final bool isStreetlightsOn;
  final int? flagPercent;

  const DioramaVisualizer({
    super.key,
    required this.isFountainOn,
    required this.fountainColor,
    required this.isBuildingLightsOn,
    required this.isStreetlightsOn,
    required this.flagPercent,
  });

  @override
  State<DioramaVisualizer> createState() => _DioramaVisualizerState();
}

class _DioramaVisualizerState extends State<DioramaVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getFountainColor() {
    switch (widget.fountainColor.toUpperCase()) {
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
        return const Color(0xFF7FD8FF); // Default cyan water
    }
  }

  @override
  Widget build(BuildContext context) {
    final waterColor = _getFountainColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0C10), Color(0xFF0B2A1C)],
          ),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 1. Ground
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(color: const Color(0xFF1A5A34)),
            ),

            // 2. Main Capitol Building Base (White Facade)
            Positioned(
              bottom: 40,
              child: Container(
                width: 220,
                height: 50,
                color: const Color(0xFFF5F5F5), // White building body
              ),
            ),

            // 3. Columns
            Positioned(
              bottom: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 8,
                    height: 50,
                    color: const Color(
                      0xFFE0E0E0,
                    ), // Slightly darker white for depth
                  ),
                ),
              ),
            ),

            // 4. Building Pediment/Roof Triangle
            Positioned(
              bottom: 90,
              child: CustomPaint(
                size: const Size(240, 25),
                painter: TrianglePainter(color: const Color(0xFFF5F5F5)),
              ),
            ),

            // 5. Daet Capitol Golden Dome
            Positioned(
              bottom: 115,
              child: Container(
                width: 60,
                height: 35,
                decoration: const BoxDecoration(
                  color: Color(0xFFC9A250), // Golden dome color
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Glowing Windows behind columns
            Positioned(
              bottom: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: 12,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.isBuildingLightsOn
                          ? const Color(0xFFFFD98A)
                          : const Color(0xFF3A2420),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      boxShadow: widget.isBuildingLightsOn
                          ? [
                              const BoxShadow(
                                color: Color(0xFFFFD98A),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  );
                }),
              ),
            ),

            // 7. Mini Flagpole and Flag
            Positioned(
              bottom: 30, // Start pole near ground
              left: 45, // Shifted to the left side of the yard
              child: Container(
                width: 3,
                height: 110, // Tall pole
                color: AppColors.cream.withValues(alpha: 0.8),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear,
              left: 48, // Aligned just right of the pole
              // Map the 0-100 percent to a height range on the visualizer pole (from bottom 40 to bottom 130)
              bottom: 40 + (85 * ((widget.flagPercent ?? 50) / 100)),
              child: _buildMiniFlag(),
            ),

            // 8. Fountain Basin
            Positioned(
              bottom: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 60,
                height: 15,
                decoration: BoxDecoration(
                  color: widget.isFountainOn
                      ? Color.alphaBlend(
                          waterColor.withValues(alpha: 0.35),
                          const Color(0xFF1B0F0F),
                        )
                      : const Color(0xFF1B0F0F),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: waterColor, width: 1.5),
                ),
              ),
            ),

            // 9. Animated Fountain Jets
            if (widget.isFountainOn)
              Positioned(
                bottom: 30,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildWaterJet(
                          waterColor,
                          25 + (_pulseController.value * 10),
                        ),
                        const SizedBox(width: 8),
                        _buildWaterJet(
                          waterColor,
                          40 +
                              (math.sin(_pulseController.value * math.pi) * 15),
                        ),
                        const SizedBox(width: 8),
                        _buildWaterJet(
                          waterColor,
                          25 + ((1 - _pulseController.value) * 10),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // 10. Streetlamps
            Positioned(bottom: 15, left: 20, child: _buildStreetLamp()),
            Positioned(bottom: 15, right: 20, child: _buildStreetLamp()),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFlag() {
    return Container(
      width: 18,
      height: 11,
      decoration: const BoxDecoration(
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
          ClipPath(
            clipper: TriangleClipper(),
            child: Container(width: 9, height: 11, color: Colors.white),
          ),
          Positioned(
            left: 2,
            top: 4.5,
            child: Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(
                color: Color(0xFFFCD116),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterJet(Color color, double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [BoxShadow(color: color, blurRadius: 6)],
      ),
    );
  }

  Widget _buildStreetLamp() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            Color lampColor = const Color(0xFF4A2A2A);
            double blur = 0;
            if (widget.isStreetlightsOn) {
              final hue = (_pulseController.value * 360) % 360;
              lampColor = HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor();
              blur = 12;
            }
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lampColor,
                boxShadow: widget.isStreetlightsOn
                    ? [BoxShadow(color: lampColor, blurRadius: blur)]
                    : [],
              ),
            );
          },
        ),
        Container(width: 2, height: 25, color: const Color(0xFF6B4A3A)),
      ],
    );
  }
}

// 1. Paints the Capitol Roof
class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Clips the white triangle on the Philippine Flag
class TriangleClipper extends CustomClipper<Path> {
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
