import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/early_warning_alert.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'alert_severity_badge.dart';

/// A list card representing a single [EarlyWarningAlert] in the dashboard.
///
/// Shows the alert title, severity badge, student name, category chip,
/// relative time, and a small status indicator dot.
class AlertCard extends StatelessWidget {
  final EarlyWarningAlert alert;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _categoryColor(alert.category);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading icon based on category
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              alert.category.icon,
              color: categoryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Main content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with severity badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AlertSeverityBadge(severity: alert.severity),
                  ],
                ),
                const SizedBox(height: 4),

                // Student name
                if (alert.studentName != null &&
                    alert.studentName!.isNotEmpty) ...[
                  Text(
                    alert.studentName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                ],

                // Category chip + relative time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.category.displayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      alert.ageLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status indicator dot at trailing edge
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: alert.status.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: alert.status.color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Maps each [AlertCategory] to a display color.
  Color _categoryColor(AlertCategory category) {
    switch (category) {
      case AlertCategory.academicDecline:
        return AppColors.warning;
      case AlertCategory.attendanceIssue:
        return AppColors.error;
      case AlertCategory.behavioralConcern:
        return AppColors.accent;
      case AlertCategory.feeDefaultRisk:
        return const Color(0xFFF97316); // orange
      case AlertCategory.dropoutRisk:
        return AppColors.error;
      case AlertCategory.healthConcern:
        return AppColors.info;
    }
  }
}
