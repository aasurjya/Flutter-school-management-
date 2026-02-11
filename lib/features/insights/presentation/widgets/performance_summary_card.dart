import 'package:flutter/material.dart';
import '../../../../data/models/student_insights.dart';

class PerformanceSummaryCard extends StatelessWidget {
  final StudentInsights insights;

  const PerformanceSummaryCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final performanceColor = _getPerformanceColor(insights.overallPercentage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Performance Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PerformanceIndicator(
                    percentage: insights.overallPercentage,
                    color: performanceColor,
                    label: insights.performanceLevel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _ComparisonRow(
                        label: 'Class Average',
                        value:
                            '${insights.classAveragePercentage.toStringAsFixed(1)}%',
                        icon: Icons.people,
                      ),
                      const SizedBox(height: 8),
                      _ComparisonRow(
                        label: 'vs Class',
                        value: _formatComparison(insights.performanceVsClass),
                        icon: insights.isAboveClassAverage
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        valueColor: insights.isAboveClassAverage
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(height: 8),
                      _ComparisonRow(
                        label: 'Class Rank',
                        value: '#${insights.classRank} of ${insights.totalInClass}',
                        icon: Icons.leaderboard,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (insights.trends.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Recent Performance Trend',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: _TrendChart(trends: insights.trends),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatComparison(double diff) {
    if (diff >= 0) {
      return '+${diff.toStringAsFixed(1)}%';
    }
    return '${diff.toStringAsFixed(1)}%';
  }
}

class _PerformanceIndicator extends StatelessWidget {
  final double percentage;
  final Color color;
  final String label;

  const _PerformanceIndicator({
    required this.percentage,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<PerformanceTrend> trends;

  const _TrendChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reversedTrends = trends.reversed.toList();

    if (reversedTrends.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final itemWidth = maxWidth / reversedTrends.length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: reversedTrends.asMap().entries.map((entry) {
            final index = entry.key;
            final trend = entry.value;
            final height = (trend.percentage / 100) * 60;

            return SizedBox(
              width: itemWidth - 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${trend.percentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: height.clamp(10, 60),
                    decoration: BoxDecoration(
                      color: _getBarColor(trend.percentage, index, reversedTrends),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shortenExamName(trend.examType),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getBarColor(double percentage, int index, List<PerformanceTrend> trends) {
    // Compare with previous to show improvement
    if (index > 0) {
      final prevPercentage = trends[index - 1].percentage;
      if (percentage > prevPercentage + 5) {
        return Colors.green;
      } else if (percentage < prevPercentage - 5) {
        return Colors.red;
      }
    }

    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _shortenExamName(String examType) {
    switch (examType) {
      case 'unit_test':
        return 'UT';
      case 'mid_term':
        return 'Mid';
      case 'final':
        return 'Final';
      case 'assignment':
        return 'Assgn';
      case 'practical':
        return 'Prac';
      case 'project':
        return 'Proj';
      default:
        return examType.substring(0, 3);
    }
  }
}
