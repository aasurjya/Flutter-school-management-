import 'package:flutter/material.dart';
import '../../../../data/models/student_insights.dart';

class SubjectPerformanceList extends StatelessWidget {
  final List<SubjectInsight> subjectInsights;

  const SubjectPerformanceList({super.key, required this.subjectInsights});

  @override
  Widget build(BuildContext context) {
    if (subjectInsights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('No subject data available'),
            const SizedBox(height: 8),
            Text(
              'Complete exams to see subject performance',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjectInsights.length,
      itemBuilder: (context, index) {
        return _SubjectCard(subject: subjectInsights[index]);
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectInsight subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final performanceColor = _getPerformanceColor(subject.percentage);
    final comparisonColor =
        subject.performanceVsClass >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSubjectDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: performanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${subject.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: performanceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subject.subjectName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _TrendIndicator(trend: subject.trend),
                          ],
                        ),
                        if (subject.subjectCode != null)
                          Text(
                            subject.subjectCode!,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: subject.percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(performanceColor),
                ),
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people,
                    label: 'Class Avg',
                    value: '${subject.classAverage.toStringAsFixed(1)}%',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: subject.performanceVsClass >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    label: 'vs Class',
                    value: _formatComparison(subject.performanceVsClass),
                    color: comparisonColor,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.leaderboard,
                    label: 'Rank',
                    value: '#${subject.subjectRank}/${subject.totalInSubject}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubjectDetails(BuildContext context) {
    final theme = Theme.of(context);
    final performanceColor = _getPerformanceColor(subject.percentage);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: performanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${subject.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: performanceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.subjectName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subject.subjectCode != null)
                            Text(
                              subject.subjectCode!,
                              style: theme.textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                    _TrendIndicator(trend: subject.trend, showLabel: true),
                  ],
                ),
                const SizedBox(height: 24),
                // Detailed stats
                _DetailRow(
                  label: 'Your Score',
                  value: '${subject.percentage.toStringAsFixed(1)}%',
                  color: performanceColor,
                ),
                _DetailRow(
                  label: 'Class Average',
                  value: '${subject.classAverage.toStringAsFixed(1)}%',
                ),
                _DetailRow(
                  label: 'Comparison',
                  value: _formatComparison(subject.performanceVsClass),
                  color: subject.performanceVsClass >= 0
                      ? Colors.green
                      : Colors.red,
                ),
                _DetailRow(
                  label: 'Class Rank',
                  value:
                      '#${subject.subjectRank} out of ${subject.totalInSubject}',
                ),
                const SizedBox(height: 24),
                // Recent scores chart
                if (subject.recentScores.isNotEmpty) ...[
                  Text(
                    'Recent Performance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: _RecentScoresChart(scores: subject.recentScores),
                  ),
                ],
                const SizedBox(height: 24),
                // Status badge
                _StatusBadge(subject: subject),
              ],
            ),
          );
        },
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

class _TrendIndicator extends StatelessWidget {
  final String trend;
  final bool showLabel;

  const _TrendIndicator({required this.trend, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final color = _getColor();
    final label = _getLabel();

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Icon(icon, color: color, size: 20);
  }

  IconData _getIcon() {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getColor() {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLabel() {
    switch (trend) {
      case 'improving':
        return 'Improving';
      case 'declining':
        return 'Declining';
      default:
        return 'Stable';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 14,
              color: color ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetailRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScoresChart extends StatelessWidget {
  final List<double> scores;

  const _RecentScoresChart({required this.scores});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: scores.asMap().entries.map((entry) {
        final index = entry.key;
        final score = entry.value;
        final height = (score / 100) * 80;
        final color = _getScoreColor(score);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: height.clamp(10, 80),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exam ${scores.length - index}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

class _StatusBadge extends StatelessWidget {
  final SubjectInsight subject;

  const _StatusBadge({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String message;
    IconData icon;
    Color color;

    if (subject.isStrength) {
      message = 'This is one of your strongest subjects! Keep it up!';
      icon = Icons.star;
      color = Colors.amber;
    } else if (subject.needsImprovement) {
      message = 'This subject needs more attention. Consider extra practice.';
      icon = Icons.priority_high;
      color = Colors.red;
    } else if (subject.trend == 'improving') {
      message = 'Great progress! Your performance is improving.';
      icon = Icons.trending_up;
      color = Colors.green;
    } else if (subject.trend == 'declining') {
      message = 'Your performance has been declining. Review recent topics.';
      icon = Icons.trending_down;
      color = Colors.orange;
    } else {
      message = 'Stable performance. Keep practicing to improve further.';
      icon = Icons.check_circle;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
