import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';
import '../widgets/score_distribution_chart.dart';

class ExamAnalyticsScreen extends ConsumerWidget {
  final String examId;

  const ExamAnalyticsScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(examAnalyticsProvider(examId));
    final distributionAsync =
        ref.watch(examScoreDistributionProvider(examId));
    final questionAnalyticsAsync =
        ref.watch(examQuestionAnalyticsProvider(examId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(examAnalyticsProvider(examId));
              ref.invalidate(examScoreDistributionProvider(examId));
              ref.invalidate(examQuestionAnalyticsProvider(examId));
            },
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          if (analytics == null) {
            return const Center(child: Text('No analytics data yet'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview stats
                _OverviewGrid(analytics: analytics),
                const SizedBox(height: 20),
                // Pass/fail chart
                _PassFailCard(analytics: analytics),
                const SizedBox(height: 20),
                // Score distribution
                distributionAsync.whenOrNull(
                      data: (dist) => Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ScoreDistributionChart(
                              distribution: dist),
                        ),
                      ),
                    ) ??
                    const SizedBox.shrink(),
                const SizedBox(height: 20),
                // Question-wise analysis
                questionAnalyticsAsync.whenOrNull(
                      data: (questions) =>
                          _QuestionAnalysisTable(questions: questions),
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final ExamAnalytics analytics;

  const _OverviewGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _MetricCard(
          icon: Icons.people_outline,
          label: 'Total Attempts',
          value: '${analytics.totalAttempts}',
          color: AppColors.info,
        ),
        _MetricCard(
          icon: Icons.percent,
          label: 'Avg Score',
          value: '${analytics.avgPercentage.toStringAsFixed(1)}%',
          color: AppColors.primary,
        ),
        _MetricCard(
          icon: Icons.arrow_upward,
          label: 'Highest',
          value: '${analytics.highestScore.toStringAsFixed(1)}',
          color: AppColors.success,
        ),
        _MetricCard(
          icon: Icons.arrow_downward,
          label: 'Lowest',
          value: '${analytics.lowestScore.toStringAsFixed(1)}',
          color: AppColors.error,
        ),
        _MetricCard(
          icon: Icons.timer_outlined,
          label: 'Avg Time',
          value: analytics.avgTimeDisplay,
          color: AppColors.accent,
        ),
        _MetricCard(
          icon: Icons.hourglass_empty,
          label: 'In Progress',
          value: '${analytics.inProgressCount}',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassFailCard extends StatelessWidget {
  final ExamAnalytics analytics;

  const _PassFailCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = analytics.passCount + analytics.failCount;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pass / Fail Ratio',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (total > 0) ...[
              // Visual bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Expanded(
                        flex: analytics.passCount,
                        child: Container(
                          color: AppColors.success,
                          child: Center(
                            child: Text(
                              '${analytics.passCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (analytics.failCount > 0)
                        Expanded(
                          flex: analytics.failCount,
                          child: Container(
                            color: AppColors.error,
                            child: Center(
                              child: Text(
                                '${analytics.failCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Passed: ${analytics.passCount}'),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Failed: ${analytics.failCount}'),
                    ],
                  ),
                  Text(
                    'Pass Rate: ${analytics.passRate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ] else
              const Center(
                child: Text('No graded attempts yet'),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionAnalysisTable extends StatelessWidget {
  final List<Map<String, dynamic>> questions;

  const _QuestionAnalysisTable({required this.questions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (questions.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question-wise Analysis',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;
              final accuracy = (q['accuracy_rate'] as num?)?.toDouble() ?? 0;
              final totalResp = q['total_responses'] ?? 0;
              final correct = q['correct_count'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _accuracyColor(accuracy),
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q['question_text']?.toString() ?? 'Question',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${accuracy.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _accuracyColor(accuracy),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: accuracy / 100,
                        backgroundColor:
                            _accuracyColor(accuracy).withAlpha(25),
                        valueColor: AlwaysStoppedAnimation(
                            _accuracyColor(accuracy)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$correct / $totalResp correct - ${q['difficulty']} - ${q['question_type']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 70) return AppColors.success;
    if (accuracy >= 40) return AppColors.warning;
    return AppColors.error;
  }
}
