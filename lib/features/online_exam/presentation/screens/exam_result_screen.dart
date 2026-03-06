import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';
import '../widgets/question_widget.dart';

class ExamResultScreen extends ConsumerWidget {
  final String attemptId;

  const ExamResultScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attemptAsync = ref.watch(examAttemptByIdProvider(attemptId));

    return attemptAsync.when(
      data: (attempt) {
        if (attempt == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Result')),
            body: const Center(child: Text('Result not found')),
          );
        }

        final isPassed = attempt.percentage >=
            40; // default pass percentage
        final examAsync =
            ref.watch(onlineExamByIdProvider(attempt.examId));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Exam Result'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.go('/online-exams'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Result summary card
                _ResultCard(attempt: attempt, isPassed: isPassed),
                const SizedBox(height: 16),
                // Statistics
                _StatsRow(attempt: attempt),
                const SizedBox(height: 16),
                // Review answers (if allowed)
                examAsync.whenOrNull(
                      data: (exam) {
                        if (exam == null) return const SizedBox.shrink();
                        if (!exam.settings.allowReview &&
                            !exam.settings.showResultImmediately) {
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'Answer review is not available for this exam.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }
                        return _AnswerReview(
                          attempt: attempt,
                          showCorrectAnswers:
                              exam.settings.showResultImmediately,
                        );
                      },
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ExamAttempt attempt;
  final bool isPassed;

  const _ResultCard({required this.attempt, required this.isPassed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isPassed ? AppColors.success : AppColors.error;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withAlpha(15), color.withAlpha(5)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Result icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPassed ? Icons.emoji_events : Icons.refresh,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            // Pass / Fail text
            Text(
              isPassed ? 'Congratulations!' : 'Keep Trying!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPassed ? 'You passed the exam' : 'You did not pass this time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Score display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  attempt.totalMarksObtained.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  ' / ${attempt.examTitle ?? ''}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Percentage
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${attempt.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ExamAttempt attempt;

  const _StatsRow({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.timer_outlined,
            label: 'Time Taken',
            value: attempt.timeTakenDisplay,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.replay,
            label: 'Attempt',
            value: '#${attempt.attemptNumber}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Status',
            value: attempt.status.label,
            color: attempt.isGraded
                ? AppColors.success
                : AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerReview extends StatelessWidget {
  final ExamAttempt attempt;
  final bool showCorrectAnswers;

  const _AnswerReview({
    required this.attempt,
    required this.showCorrectAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responses = attempt.responses ?? [];

    if (responses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No responses to review')),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Answer Review',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...responses.asMap().entries.map((entry) {
              final idx = entry.key;
              final resp = entry.value;
              final question = resp.question;
              if (question == null) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (idx > 0) const Divider(height: 32),
                  // Question number and result badge
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: resp.isCorrect == true
                            ? AppColors.success
                            : resp.isCorrect == false
                                ? AppColors.error
                                : Colors.grey,
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (resp.isCorrect != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: resp.isCorrect!
                                ? AppColors.success.withAlpha(20)
                                : AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            resp.isCorrect! ? 'Correct' : 'Incorrect',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: resp.isCorrect!
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${resp.marksAwarded.toStringAsFixed(1)} / ${question.marks.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  QuestionWidget(
                    question: question,
                    currentResponse: resp.response,
                    readOnly: true,
                    showCorrectAnswer: showCorrectAnswers,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
