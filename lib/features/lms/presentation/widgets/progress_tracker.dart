import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Circular progress ring widget for course completion
class CourseProgressRing extends StatelessWidget {
  final double progressPercentage;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? center;

  const CourseProgressRing({
    super.key,
    required this.progressPercentage,
    this.size = 100,
    this.strokeWidth = 10,
    this.progressColor,
    this.backgroundColor,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (progressPercentage / 100).clamp(0.0, 1.0);
    final color = progressColor ??
        (progressPercentage >= 100 ? AppColors.success : AppColors.primary);
    final bgColor = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.2));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: center ??
                Text(
                  '${progressPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Detailed progress tracker card with fl_chart pie chart
class ProgressTrackerCard extends StatelessWidget {
  final int totalContent;
  final int completedContent;
  final int inProgressContent;
  final int notStartedContent;
  final int totalModules;
  final int completedModules;
  final int timeSpentSeconds;

  const ProgressTrackerCard({
    super.key,
    required this.totalContent,
    required this.completedContent,
    required this.inProgressContent,
    required this.notStartedContent,
    required this.totalModules,
    required this.completedModules,
    this.timeSpentSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage =
        totalContent > 0 ? (completedContent / totalContent * 100) : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie chart
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.success,
                        value: completedContent.toDouble(),
                        title: '$completedContent',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: AppColors.warning,
                        value: inProgressContent.toDouble(),
                        title: inProgressContent > 0
                            ? '$inProgressContent'
                            : '',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.3),
                        value: notStartedContent > 0
                            ? notStartedContent.toDouble()
                            : (totalContent == 0 ? 1 : 0),
                        title: '',
                        radius: 25,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: percentage >= 100
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Course Completion',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LegendItem(
                      color: AppColors.success,
                      label: 'Completed',
                      value: '$completedContent',
                    ),
                    const SizedBox(height: 4),
                    _LegendItem(
                      color: AppColors.warning,
                      label: 'In Progress',
                      value: '$inProgressContent',
                    ),
                    const SizedBox(height: 4),
                    _LegendItem(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.4),
                      label: 'Not Started',
                      value: '$notStartedContent',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.view_module_outlined,
                label: 'Modules',
                value: '$completedModules/$totalModules',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.library_books_outlined,
                label: 'Content',
                value: '$completedContent/$totalContent',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.access_time,
                label: 'Time Spent',
                value: _formatTime(timeSpentSeconds),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '0m';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
