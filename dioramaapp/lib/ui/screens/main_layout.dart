import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/esp_state.dart';
import '../../providers/diorama_provider.dart';

import '../tabs/home_tab.dart';
import '../tabs/control_tab.dart';
import '../tabs/flag_tab.dart';
import '../tabs/music_tab.dart';
import '../tabs/quiz_tab.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _leaving = false;

  // Actual application tabs
  final List<Widget> _tabs = const [
    HomeTab(),
    ControlTab(),
    FlagTab(),
    MusicTab(),
    QuizTab(),
  ];

  /// Safely returns to the connect screen.
  /// Navigates after the current frame, clears the whole stack, and only
  /// then switches demo mode off, so nothing rebuilds mid-teardown.
  void _goToConnectScreen(DioramaProvider provider) {
    if (_leaving) return;
    _leaving = true;
    provider.leaveFlagTab();
    if (!provider.isDemoMode) provider.disconnect();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      // Switch demo mode off once the old screen is gone.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.disableDemoMode();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DioramaProvider>(context);
    final state = provider.state;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state, provider),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(EspState state, DioramaProvider provider) {
    final bool isOnline = state.canControl;
    final bool isDemo = provider.isDemoMode;

    final String pillText = isDemo
        ? 'DEMO MODE'
        : state.dataStale && state.isConnected
        ? 'Status stale'
        : isOnline
        ? (state.slaveOnline
              ? 'Wi-Fi ? ${state.pingMs} ms'
              : 'Wi-Fi ? slave offline')
        : 'Offline ? tap to connect';

    final Color pillColor = isDemo
        ? AppColors.gold
        : isOnline
        ? const Color(0xFF6DFFA3)
        : const Color(0xFFFF9A9A);

    final Color pillBg = isDemo
        ? AppColors.gold.withValues(alpha: 0.18)
        : isOnline
        ? AppColors.green.withValues(alpha: 0.18)
        : AppColors.red.withValues(alpha: 0.2);

    final Color pillBorder = isDemo
        ? AppColors.gold.withValues(alpha: 0.5)
        : isOnline
        ? AppColors.green.withValues(alpha: 0.5)
        : AppColors.red.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESP32 CONTROLLER',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Capitol Diorama',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: AppColors.cream,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (isDemo || !isOnline) {
                _goToConnectScreen(provider);
              } else {
                _goToConnectScreen(provider);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                border: Border.all(color: pillBorder),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                pillText,
                style: TextStyle(color: pillColor, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabWidth = screenWidth / 5;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0x73000000),
        border: Border(top: BorderSide(color: AppColors.lineBorder)),
      ),
      padding: const EdgeInsets.only(bottom: 6),
      child: Stack(
        children: [
          // Animated top gradient indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            left: tabWidth * _currentIndex,
            top: 0,
            width: tabWidth,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [AppColors.red, AppColors.green],
                ),
              ),
            ),
          ),

          // Navigation buttons
          Row(
            children: [
              _buildNavItem(0, '🏠', 'Home'),
              _buildNavItem(1, '🎛️', 'Control'),
              _buildNavItem(2, '🚩', 'Flag'),
              _buildNavItem(3, '🎵', 'Music'),
              _buildNavItem(4, '🧠', 'Quiz'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label) {
    final bool isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_currentIndex == 2 && index != 2) {
            context.read<DioramaProvider>().leaveFlagTab();
          }
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isActive ? 1.0 : 0.55,
          child: Padding(
            padding: const EdgeInsets.only(top: 9, bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(0, isActive ? -3 : 0, 0)
                    ..scaleByDouble(
                      isActive ? 1.15 : 1.0,
                      isActive ? 1.15 : 1.0,
                      1.0,
                      1.0,
                    ),
                  child: Text(icon, style: const TextStyle(fontSize: 19)),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.cream),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
