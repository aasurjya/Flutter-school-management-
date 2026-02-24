import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/attendance_insights.dart';
import '../../../../shared/widgets/glass_card.dart';

class ChronicAbsenteeCard extends StatelessWidget {
  final ChronicAbsentee absentee;
  final VoidCallback? onTap;

  const ChronicAbsenteeCard({
    super.key,
    required this.absentee,
    this.onTap,
  });

  Color get _severityColor {
    if (absentee.absenceRate > 40) return AppColors.error;
    if (absentee.absenceRate > 30) return AppColors.warning;
    return const Color(0xFFF97316);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _severityColor.withValues(alpha: 0.15),
            child: Text(
              absentee.studentName.isNotEmpty
                  ? absentee.studentName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: _severityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  absentee.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${absentee.absentDays} absent of ${absentee.totalDays} days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${absentee.absenceRate.toStringAsFixed(0)}%',
              style: TextStyle(
                color: _severityColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
