import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/quiz.dart';
import '../../providers/assessment_provider.dart';

class TakeQuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String studentId;

  const TakeQuizScreen({
    super.key,
    required this.quizId,
    required this.studentId,
  });

  @override
  ConsumerState<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends ConsumerState<TakeQuizScreen> {
  @override
  void initState() {
    super.initState();
    // Start the quiz session
    Future.microtask(() {
      ref
          .read(quizSessionProvider.notifier)
          .startQuiz(widget.quizId, widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(quizSessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Scaffold(
              body: Center(child: Text('Quiz not started')),
            );
          }
          return _QuizContent(session: session);
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Your progress will be saved. You can continue later if the quiz is still available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              ref.read(quizSessionProvider.notifier).cancelQuiz();
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _QuizContent extends ConsumerWidget {
  final QuizSession session;

  const _QuizContent({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final question = session.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context, ref),
        ),
        title: Text(session.quiz.title),
        actions: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _getTimerColor(session.remainingSeconds),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  session.timerDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: session.progress,
            backgroundColor: Colors.grey[200],
          ),
          // Question info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${session.currentQuestionIndex + 1} of ${session.totalQuestions}',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${question.marks} marks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.questionText,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Answer options
                  _buildAnswerWidget(context, ref, question),
                ],
              ),
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (!session.isFirstQuestion)
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(quizSessionProvider.notifier).previousQuestion(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),
                const Spacer(),
                // Question navigator
                TextButton(
                  onPressed: () => _showQuestionNavigator(context, ref),
                  child: Text('${session.answeredCount}/${session.totalQuestions} answered'),
                ),
                const Spacer(),
                if (session.isLastQuestion)
                  FilledButton.icon(
                    onPressed: () => _showSubmitConfirmation(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('Submit'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(quizSessionProvider.notifier).nextQuestion(),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerWidget(
    BuildContext context,
    WidgetRef ref,
    QuizQuestion question,
  ) {
    final currentAnswer = session.currentAnswers[question.id];

    switch (question.questionType) {
      case 'mcq':
        return _MCQOptions(
          question: question,
          selectedAnswer: currentAnswer,
          onSelect: (answer) => ref
              .read(quizSessionProvider.notifier)
              .answerQuestion(question.id, answer),
        );
      case 'true_false':
        return _TrueFalseOptions(
          selectedAnswer: currentAnswer,
          onSelect: (answer) => ref
              .read(quizSessionProvider.notifier)
              .answerQuestion(question.id, answer),
        );
      case 'short_answer':
      case 'long_answer':
        return _TextAnswerField(
          initialValue: currentAnswer,
          isLong: question.questionType == 'long_answer',
          onChanged: (answer) => ref
              .read(quizSessionProvider.notifier)
              .answerQuestion(question.id, answer),
        );
      default:
        return const Text('Unknown question type');
    }
  }

  Color _getTimerColor(int seconds) {
    if (seconds <= 60) return Colors.red;
    if (seconds <= 300) return Colors.orange;
    return Colors.green;
  }

  void _showExitConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Your progress will be saved. You can continue later if the quiz is still available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              ref.read(quizSessionProvider.notifier).cancelQuiz();
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showQuestionNavigator(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jump to Question',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(session.questions.length, (index) {
                final q = session.questions[index];
                final isAnswered = session.currentAnswers[q.id] != null &&
                    session.currentAnswers[q.id]!.isNotEmpty;
                final isCurrent = index == session.currentQuestionIndex;

                return InkWell(
                  onTap: () {
                    ref.read(quizSessionProvider.notifier).goToQuestion(index);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : isAnswered
                              ? Colors.green
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent || isAnswered
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _LegendItem(color: Colors.green, label: 'Answered'),
                const SizedBox(width: 16),
                _LegendItem(
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Current',
                ),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.grey[200]!, label: 'Unanswered'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitConfirmation(BuildContext context, WidgetRef ref) {
    final unanswered = session.totalQuestions - session.answeredCount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Answered: ${session.answeredCount}/${session.totalQuestions}'),
            if (unanswered > 0)
              Text(
                'Warning: $unanswered questions are unanswered!',
                style: const TextStyle(color: Colors.orange),
              ),
            const SizedBox(height: 8),
            const Text('Are you sure you want to submit?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final result =
                  await ref.read(quizSessionProvider.notifier).submitQuiz();
              if (result != null && context.mounted) {
                context.pushReplacement(
                  '/assessments/result/${result.id}',
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MCQOptions extends StatelessWidget {
  final QuizQuestion question;
  final String? selectedAnswer;
  final Function(String) onSelect;

  const _MCQOptions({
    required this.question,
    this.selectedAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? {};
    final optionKeys = options.keys.toList()..sort();

    return Column(
      children: optionKeys.map((key) {
        final isSelected = selectedAnswer == key;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: () => onSelect(key),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      options[key]?.toString() ?? '',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TrueFalseOptions extends StatelessWidget {
  final String? selectedAnswer;
  final Function(String) onSelect;

  const _TrueFalseOptions({
    this.selectedAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrueFalseButton(
            label: 'True',
            isSelected: selectedAnswer == 'true',
            onTap: () => onSelect('true'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TrueFalseButton(
            label: 'False',
            isSelected: selectedAnswer == 'false',
            onTap: () => onSelect('false'),
          ),
        ),
      ],
    );
  }
}

class _TrueFalseButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrueFalseButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : null,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              label == 'True' ? Icons.check_circle : Icons.cancel,
              size: 48,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? theme.colorScheme.primary : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAnswerField extends StatefulWidget {
  final String? initialValue;
  final bool isLong;
  final Function(String) onChanged;

  const _TextAnswerField({
    this.initialValue,
    required this.isLong,
    required this.onChanged,
  });

  @override
  State<_TextAnswerField> createState() => _TextAnswerFieldState();
}

class _TextAnswerFieldState extends State<_TextAnswerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: widget.isLong ? 8 : 3,
      decoration: InputDecoration(
        hintText: widget.isLong
            ? 'Enter your detailed answer here...'
            : 'Enter your answer here...',
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
