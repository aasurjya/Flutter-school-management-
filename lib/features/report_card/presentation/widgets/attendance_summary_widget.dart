import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class AttendanceSummaryWidget extends StatelessWidget {
  final int daysPresent;
  final int totalDays;
  final double attendancePercentage;

  const AttendanceSummaryWidget({
    super.key,
    required this.daysPresent,
    required this.totalDays,
    required this.attendancePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final daysAbsent = totalDays - daysPresent;
    final isGood = attendancePercentage >= 75;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular Progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: attendancePercentage / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      isGood ? AppColors.success : AppColors.warning,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${attendancePercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isGood ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Stats
          Expanded(
            child: Column(
              children: [
                _AttRow(
                  label: 'Working Days',
                  value: '$totalDays',
                  color: AppColors.textPrimaryLight,
                  icon: Icons.calendar_today,
                ),
                const Divider(height: 16),
                _AttRow(
                  label: 'Days Present',
                  value: '$daysPresent',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
                const Divider(height: 16),
                _AttRow(
                  label: 'Days Absent',
                  value: '$daysAbsent',
                  color: AppColors.error,
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
          ),

          // Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isGood
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  isGood
                      ? Icons.thumb_up_outlined
                      : Icons.warning_outlined,
                  color: isGood ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(height: 4),
                Text(
                  isGood ? 'Good' : 'Low',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isGood ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _AttRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
