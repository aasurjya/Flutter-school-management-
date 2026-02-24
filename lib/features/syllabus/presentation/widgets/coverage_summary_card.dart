import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/syllabus_topic.dart';
import 'coverage_progress_bar.dart';

/// GlassCard showing subject coverage overview.
///
/// Displays the subject name, class + section context, a circular coverage
/// percentage indicator, topic counts, and a segmented [CoverageProgressBar]
/// at the bottom. Matches the style of existing dashboard stat cards.
class CoverageSummaryCard extends StatelessWidget {
  final SyllabusCoverageSummary summary;
  final VoidCallback? onTap;

  const CoverageSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = summary.coveragePercentage.clamp(0, 100).toDouble();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular progress indicator
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 5,
                        backgroundColor:
                            Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColor(percentage),
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _progressColor(percentage),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Subject name + class context
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.subjectName ?? 'Subject',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _classSection,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${summary.completedTopics}/${summary.totalTopics} topics',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Segmented progress bar
          CoverageProgressBar(
            completed: summary.completedTopics,
            inProgress: summary.inProgressTopics,
            notStarted: summary.notStartedTopics,
            skipped: summary.skippedTopics,
          ),
        ],
      ),
    );
  }

  String get _classSection {
    final parts = <String>[];
    if (summary.className != null) parts.add(summary.className!);
    if (summary.sectionName != null) parts.add(summary.sectionName!);
    return parts.isNotEmpty ? parts.join(' - ') : 'Class';
  }

  Color _progressColor(double percentage) {
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 40) return AppColors.warning;
    return AppColors.error;
  }
}
