// lib/ui/screens/intro_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  // Phase controls the storytelling timeline (0 to 5)
  int _phase = 0;
  final List<Timer> _timers = [];
  final Random _random = Random();

  // Background stars
  late List<Widget> _stars;

  @override
  void initState() {
    super.initState();
    _generateStars();
    _startTimeline();
  }

  void _generateStars() {
    _stars = List.generate(40, (index) {
      final double top = _random.nextDouble() * 400; // Top half of screen
      final double left = _random.nextDouble() * 400;
      final int delay = _random.nextInt(2000);
      
      return Positioned(
        top: top,
        left: left,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.1, end: 1.0),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOutSine,
          builder: (context, value, child) {
            // Simulated twinkling using a sine wave on the tweened value
            final opacity = (sin((value * pi) + delay) + 1) / 2 * 0.8 + 0.1;
            return Opacity(
              opacity: opacity,
              child: Container(
                width: 2,
                height: 2,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _startTimeline() {
    // 1. Initial fade in (1898)
    _timers.add(Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _phase = 1);
    }));

    // 2. Building construction (Capitol takes shape)
    _timers.add(Timer(const Duration(milliseconds: 4000), () {
      if (mounted) setState(() => _phase = 2);
    }));

    // 3. Sun rises, moon fades (Every dawn)
    _timers.add(Timer(const Duration(milliseconds: 8200), () {
      if (mounted) setState(() => _phase = 3);
    }));

    // 4. Technology meets heritage (Lights, Fountain, Tags)
    _timers.add(Timer(const Duration(milliseconds: 12000), () {
      if (mounted) setState(() => _phase = 4);
    }));

    // 5. Final Title & Begin Button
    _timers.add(Timer(const Duration(milliseconds: 15500), () {
      if (mounted) setState(() => _phase = 5);
    }));
  }

  Future<void> _skipIntro() async {
    for (var timer in _timers) {
      timer.cancel();
    }
    
    // Save to device storage so intro won't show again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);

    if (mounted) {
      // Navigate directly to the ConnectScreen (which is mapped to '/' in main.dart)
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  // Helper to determine active captions
  String get _currentSmallCaption {
    if (_phase == 1) return 'Daet, Camarines Norte · 1898';
    if (_phase == 2) return 'And then, a home for its people';
    if (_phase == 3) return 'Every dawn';
    if (_phase == 4) return 'Today, heritage meets technology';
    return '';
  }

  String get _currentLargeCaption {
    if (_phase == 1) return 'Where the nation’s colors first rose over Luzon';
    if (_phase == 2) return 'The Provincial Capitol takes shape';
    if (_phase == 3) return 'The flag still rises';
    if (_phase == 4) return 'Water · Light · Sound · Motion';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _phase >= 3
                ? [const Color(0xFF4A0F16), const Color(0xFFC2492C), const Color(0xFF1A6A3A)] // Sunrise
                : [const Color(0xFF050208), const Color(0xFF12060D), const Color(0xFF06241A)], // Night
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Stars (fade out at sunrise)
            AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity: _phase >= 3 ? 0.0 : 1.0,
              child: Stack(children: _stars),
            ),

            // 2. Moon (fades out at sunrise)
            AnimatedPositioned(
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              top: _phase >= 3 ? -50 : 60,
              right: 46,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _phase >= 3 ? 0.0 : 1.0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
            ),

            // 3. Sun (Rises at phase 3)
            AnimatedPositioned(
              duration: const Duration(seconds: 5),
              curve: Curves.easeOutCubic,
              bottom: _phase >= 3 ? size.height * 0.44 : -120,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFFFF2B0), AppColors.gold, Colors.transparent],
                    stops: [0.0, 0.55, 0.72],
                  ),
                ),
              ),
            ),

            // 4. Center Capitol Silhouette (Builds at phase 2, lights at phase 4)
            Positioned(
              top: size.height * 0.35,
              child: _buildAnimatedCapitol(),
            ),

            // 5. Captions
            Positioned(
              bottom: size.height * 0.25,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: (_phase >= 1 && _phase < 5) ? 1.0 : 0.0,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        _currentSmallCaption,
                        key: ValueKey(_currentSmallCaption),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        _currentLargeCaption,
                        key: ValueKey(_currentLargeCaption),
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Technology Tags (Phase 4)
            Positioned(
              bottom: size.height * 0.15,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: _phase >= 4 && _phase < 5 ? 1.0 : 0.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTag('⛲ Water'),
                    const SizedBox(width: 8),
                    _buildTag('💡 Light'),
                    const SizedBox(width: 8),
                    _buildTag('🔊 Sound'),
                    const SizedBox(width: 8),
                    _buildTag('⚡ ESP32', isChip: true),
                  ],
                ),
              ),
            ),

            // 7. Final Main Title (Phase 5)
            Positioned(
              top: size.height * 0.55,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: _phase == 5 ? 1.0 : 0.0,
                child: Column(
                  children: [
                    const Text(
                      'DAET CAPITOL\nDIORAMA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        height: 1.15,
                        shadows: [
                          Shadow(color: Color(0x8C1DB954), blurRadius: 22) // Green glow
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'INTERACTIVE IOT HERITAGE EXPERIENCE',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _skipIntro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: const Text('Tap to begin'),
                    ),
                  ],
                ),
              ),
            ),

            // 8. Skip Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: _skipIntro,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.lineBorder),
                  ),
                  child: const Text(
                    'Skip ›',
                    style: TextStyle(color: AppColors.cream, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCapitol() {
    return AnimatedScale(
      duration: const Duration(seconds: 15),
      scale: _phase > 0 ? 1.1 : 0.95,
      curve: Curves.easeOut,
      child: SizedBox(
        width: 260,
        height: 140,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Base Building (Phase 2)
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _phase >= 2 ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                transform: Matrix4.translationValues(0, _phase >= 2 ? 0 : 20, 0),
                width: 240,
                height: 60,
                color: const Color(0xFF1A1A1A), // Silhouette
              ),
            ),

            // Pillars & Roof (Phase 2)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1200),
              opacity: _phase >= 2 ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                transform: Matrix4.translationValues(0, _phase >= 2 ? 0 : -30, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(200, 25),
                      painter: SilhouetteTrianglePainter(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) => 
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 6,
                          height: 60,
                          color: const Color(0xFF111111),
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Windows / Lights (Phase 4)
            Positioned(
              bottom: 20,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _phase >= 4 ? 1.0 : 0.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) => 
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      width: 10,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD98A),
                        boxShadow: [
                          BoxShadow(color: Color(0xFFFFD98A), blurRadius: 6)
                        ],
                      ),
                    )
                  ),
                ),
              ),
            ),

            // Fountain (Phase 4)
            Positioned(
              bottom: -5,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _phase >= 4 ? 1.0 : 0.0,
                child: Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2A1C),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFF7FD8FF), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF7FD8FF), blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool isChip = false}) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      scale: _phase >= 4 ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: isChip ? AppColors.red : AppColors.green),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.cream, fontSize: 12),
        ),
      ),
    );
  }
}

// Simple Painter for the Roof Silhouette
class SilhouetteTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF1A1A1A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
