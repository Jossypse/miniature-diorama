// lib/ui/widgets/sensor_badge.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class SensorBadge extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool isActive;
  
  /// If provided, the badge will glow with this specific color (used for the Color Sensor).
  /// If null, it defaults to the standard green glow.
  final Color? dynamicColor;

  const SensorBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isActive,
    this.dynamicColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the glow and border color
    final Color activeColor = dynamicColor ?? AppColors.green;
    
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor : AppColors.lineBorder,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: -2,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Dynamic Color Circle
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
                      ? [BoxShadow(color: dynamicColor!, blurRadius: 14)] 
                      : [],
                ),
              )
            else
              Text(
                icon,
                style: const TextStyle(fontSize: 20, height: 1.1),
              ),
            
            const SizedBox(height: 4),
            
            // Sensor Label
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.cream,
              ),
            ),
            
            const SizedBox(height: 3),
            
            // Live Value
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
}