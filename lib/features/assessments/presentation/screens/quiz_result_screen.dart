import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/quiz.dart';
import '../../providers/assessment_provider.dart';

class QuizResultScreen extends ConsumerWidget {
  final String attemptId;

  const QuizResultScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptAsync = ref.watch(attemptByIdProvider(attemptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/assessments'),
        ),
      ),
      body: attemptAsync.when(
        data: (attempt) {
          if (attempt == null) {
            return const Center(child: Text('Result not found'));
          }
          return _ResultContent(attempt: attempt);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ResultContent extends ConsumerWidget {
  final QuizAttempt attempt;

  const _ResultContent({required this.attempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPassed = attempt.isPassed;
    final percentage = attempt.percentage ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Result header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Result icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed
                          ? Colors.green.withAlpha(25)
                          : Colors.red.withAlpha(25),
                    ),
                    child: Icon(
                      isPassed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                      size: 50,
                      color: isPassed ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPassed ? 'Congratulations!' : 'Keep Practicing!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPassed ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPassed
                        ? 'You have passed the quiz!'
                        : 'You did not meet the passing criteria.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Score card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Circular score indicator
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              _getScoreColor(percentage),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(percentage),
                              ),
                            ),
                            Text(
                              'Score',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Score breakdown
                  _ScoreRow(
                    label: 'Total Marks',
                    value: '${attempt.totalMarks}',
                  ),
                  const Divider(),
                  _ScoreRow(
                    label: 'Marks Obtained',
                    value: '${attempt.obtainedMarks}',
                    valueColor: _getScoreColor(percentage),
                  ),
                  const Divider(),
                  _ScoreRow(
                    label: 'Status',
                    value: attempt.statusDisplay,
                    valueColor: isPassed ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Time card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.play_arrow,
                    label: 'Started',
                    value: _formatDateTime(attempt.startedAt),
                  ),
                  if (attempt.submittedAt != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.stop,
                      label: 'Submitted',
                      value: _formatDateTime(attempt.submittedAt!),
                    ),
                  ],
                  if (attempt.durationDisplay != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.timer,
                      label: 'Duration',
                      value: attempt.durationDisplay!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/assessments'),
                  icon: const Icon(Icons.list),
                  label: const Text('All Quizzes'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _viewAnswers(context),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Answers'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _viewAnswers(BuildContext context) {
    context.push('/assessments/review/${attempt.id}');
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ScoreRow({
    required this.label,
    required this.value,
    this.valueColor,
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
