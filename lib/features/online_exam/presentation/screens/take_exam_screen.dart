import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';
import '../widgets/exam_timer.dart';
import '../widgets/question_navigator.dart';
import '../widgets/question_widget.dart';

class TakeExamScreen extends ConsumerStatefulWidget {
  final String examId;
  final String studentId;

  const TakeExamScreen({
    super.key,
    required this.examId,
    required this.studentId,
  });

  @override
  ConsumerState<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends ConsumerState<TakeExamScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref
          .read(examSessionProvider.notifier)
          .startExam(widget.examId, widget.studentId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Track tab/app switches for proctoring
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(examSessionProvider.notifier).recordTabSwitch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(examSessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitConfirmation();
      },
      child: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Scaffold(
              body: Center(child: Text('Exam not started')),
            );
          }
          return _ExamInterface(session: session);
        },
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading exam...'),
              ],
            ),
          ),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to start exam',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Exam?'),
        content: const Text(
          'Your answers will be saved. You can resume if the exam is still active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Exam'),
          ),
          TextButton(
            onPressed: () {
              ref.read(examSessionProvider.notifier).cancelExam();
              Navigator.pop(ctx);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _ExamInterface extends ConsumerWidget {
  final OnlineExamSession session;

  const _ExamInterface({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final question = session.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context, ref),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.exam.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (session.sections.length > 1)
              Text(
                session.currentSection.title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          ExamTimer(
            remainingSeconds: session.remainingSeconds,
            totalSeconds: session.exam.durationMinutes * 60,
            compact: true,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _ProgressBar(session: session),
          // Section tabs (if multiple sections)
          if (session.sections.length > 1)
            _SectionTabs(
              session: session,
              onSectionTap: (idx) => ref
                  .read(examSessionProvider.notifier)
                  .goToQuestion(idx, 0),
            ),
          // Question info bar
          _QuestionInfoBar(
            session: session,
            onFlag: () => ref
                .read(examSessionProvider.notifier)
                .toggleQuestionFlag(question.id),
          ),
          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: QuestionWidget(
                key: ValueKey(question.id),
                question: question,
                currentResponse: session.responses[question.id],
                flaggedForReview: session.isQuestionFlagged(question.id),
                onAnswer: (response) => ref
                    .read(examSessionProvider.notifier)
                    .answerQuestion(question.id, response),
              ),
            ),
          ),
          // Bottom navigation
          _BottomNavBar(session: session),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Exam?'),
        content: const Text(
          'Your answers will be saved. You can resume if the exam is still active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              ref.read(examSessionProvider.notifier).cancelExam();
              Navigator.pop(ctx);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

// ==================== PROGRESS BAR ====================

class _ProgressBar extends StatelessWidget {
  final OnlineExamSession session;

  const _ProgressBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        value: session.progress,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(
          session.progress >= 1.0 ? AppColors.success : theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ==================== SECTION TABS ====================

class _SectionTabs extends StatelessWidget {
  final OnlineExamSession session;
  final void Function(int) onSectionTap;

  const _SectionTabs({required this.session, required this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(60),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: session.sections.length,
        itemBuilder: (context, index) {
          final section = session.sections[index];
          final isCurrent = index == session.currentSectionIndex;
          final questions = session.sectionQuestions[section.id] ?? [];
          final answered = questions
              .where((q) => session.isQuestionAnswered(q.id))
              .length;

          return GestureDetector(
            onTap: () => onSectionTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCurrent
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.white.withAlpha(50)
                            : theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$answered/${questions.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCurrent
                              ? Colors.white
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== QUESTION INFO BAR ====================

class _QuestionInfoBar extends StatelessWidget {
  final OnlineExamSession session;
  final VoidCallback onFlag;

  const _QuestionInfoBar({required this.session, required this.onFlag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = session.currentQuestion;
    final isFlagged = session.isQuestionFlagged(question.id);
    final globalIdx = session.globalQuestionIndex + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(40),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Q $globalIdx / ${session.totalQuestions}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const Spacer(),
          // Flag button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFlag,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFlagged ? Icons.flag : Icons.flag_outlined,
                      size: 20,
                      color: isFlagged
                          ? AppColors.warning
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFlagged ? 'Flagged' : 'Flag',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFlagged
                            ? AppColors.warning
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isFlagged ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== BOTTOM NAVIGATION ====================

class _BottomNavBar extends ConsumerWidget {
  final OnlineExamSession session;

  const _BottomNavBar({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFirstQuestion =
        session.currentSectionIndex == 0 &&
        session.currentQuestionIndex == 0;

    final currentQuestions = session.currentSectionQuestionList;
    final isLastQuestion =
        session.currentSectionIndex == session.sections.length - 1 &&
        session.currentQuestionIndex == currentQuestions.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (!isFirstQuestion)
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(examSessionProvider.notifier).previousQuestion(),
              icon: const Icon(Icons.chevron_left, size: 20),
              label: const Text('Prev'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            )
          else
            const SizedBox(width: 80),
          const Spacer(),
          // Question navigator button
          TextButton.icon(
            onPressed: () => _showNavigator(context, ref),
            icon: const Icon(Icons.grid_view, size: 18),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${session.answeredCount}/${session.totalQuestions}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (session.flaggedCount > 0)
                  Text(
                    '${session.flaggedCount} flagged',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          // Next / Submit button
          if (isLastQuestion)
            FilledButton.icon(
              onPressed: () => _showSubmitConfirmation(context, ref),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text('Submit'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () =>
                  ref.read(examSessionProvider.notifier).nextQuestion(),
              icon: const Text('Next'),
              label: const Icon(Icons.chevron_right, size: 20),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  void _showNavigator(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuestionNavigator(
        session: session,
        onQuestionTap: (sectionIdx, questionIdx) {
          ref
              .read(examSessionProvider.notifier)
              .goToQuestion(sectionIdx, questionIdx);
        },
      ),
    );
  }

  void _showSubmitConfirmation(BuildContext context, WidgetRef ref) {
    final unanswered = session.totalQuestions - session.answeredCount;
    final flagged = session.flaggedCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(
              label: 'Answered',
              value: '${session.answeredCount} / ${session.totalQuestions}',
              color: AppColors.success,
            ),
            if (unanswered > 0) ...[
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Unanswered',
                value: '$unanswered',
                color: AppColors.error,
              ),
            ],
            if (flagged > 0) ...[
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Flagged for review',
                value: '$flagged',
                color: AppColors.warning,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              unanswered > 0
                  ? 'You have $unanswered unanswered questions. Are you sure you want to submit?'
                  : 'Are you sure you want to submit your exam?',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review Again'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result =
                  await ref.read(examSessionProvider.notifier).submitExam();
              if (result != null && context.mounted) {
                context.pushReplacement(
                  '/online-exams/result/${result.id}',
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
