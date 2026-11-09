// lib/ui/widgets/activity_log.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ActivityLog extends StatelessWidget {
  /// The list of log messages. Assumed to be ordered with the newest at index 0.
  final List<String> logs;

  const ActivityLog({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140, // Fixed height similar to the prototype's max-height
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
          
          Expanded(
            child: logs.isEmpty
                ? const Text(
                    '> Waiting for connection...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFFFD0C0),
                      height: 1.6,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      // Provide a slight fade out for older logs to draw attention to the top (newest)
                      final double opacity = 1.0 - (index * 0.15).clamp(0.0, 0.7);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFFFFD0C0), // Pale orange/cream text
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}