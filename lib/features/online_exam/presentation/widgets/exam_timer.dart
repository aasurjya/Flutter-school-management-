import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExamTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool compact;

  const ExamTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    final color = _getTimerColor();

    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    String display;
    if (hours > 0) {
      display =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      display =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              display,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                display,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (remainingSeconds <= 60) return AppColors.error;
    if (remainingSeconds <= 300) return AppColors.warning;
    return AppColors.success;
  }
}
