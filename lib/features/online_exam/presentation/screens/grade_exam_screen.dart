import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';
import '../widgets/question_widget.dart';

class GradeExamScreen extends ConsumerStatefulWidget {
  final String attemptId;

  const GradeExamScreen({super.key, required this.attemptId});

  @override
  ConsumerState<GradeExamScreen> createState() => _GradeExamScreenState();
}

class _GradeExamScreenState extends ConsumerState<GradeExamScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(gradingProvider.notifier).loadAttempt(widget.attemptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(gradingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Exam'),
        actions: [
          if (state.attempt != null && !state.attempt!.isGraded)
            FilledButton(
              onPressed: state.allGraded
                  ? () async {
                      final result = await ref
                          .read(gradingProvider.notifier)
                          .finalizeGrading();
                      if (result != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Grading finalized successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.pop();
                      }
                    }
                  : null,
              child: const Text('Finalize'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.attempt == null
          ? const Center(child: CircularProgressIndicator())
          : state.attempt == null
              ? const Center(child: Text('Attempt not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student info card
                      _StudentInfoCard(attempt: state.attempt!),
                      const SizedBox(height: 16),
                      // Responses to grade
                      Text(
                        'Subjective Questions to Grade',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (state.subjectiveResponses.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                  'All questions were auto-graded. No subjective grading needed.'),
                            ),
                          ),
                        )
                      else
                        ...state.subjectiveResponses
                            .asMap()
                            .entries
                            .map((entry) {
                          final idx = entry.key;
                          final resp = entry.value;
                          final question = resp.question;
                          if (question == null) {
                            return const SizedBox.shrink();
                          }

                          return _GradeQuestionCard(
                            index: idx + 1,
                            response: resp,
                            question: question,
                            onGrade: (marks, isCorrect) {
                              ref
                                  .read(gradingProvider.notifier)
                                  .gradeResponse(
                                      resp.id, marks, isCorrect);
                            },
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  final ExamAttempt attempt;

  const _StudentInfoCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withAlpha(25),
              child: Text(
                (attempt.studentName ?? 'S')[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.studentName ?? 'Student',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${attempt.examTitle ?? 'Exam'} - Attempt #${attempt.attemptNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${attempt.totalMarksObtained.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'marks so far',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeQuestionCard extends StatefulWidget {
  final int index;
  final ExamResponse response;
  final ExamQuestion question;
  final void Function(double marks, bool isCorrect) onGrade;

  const _GradeQuestionCard({
    required this.index,
    required this.response,
    required this.question,
    required this.onGrade,
  });

  @override
  State<_GradeQuestionCard> createState() => _GradeQuestionCardState();
}

class _GradeQuestionCardState extends State<_GradeQuestionCard> {
  late TextEditingController _marksController;

  @override
  void initState() {
    super.initState();
    _marksController = TextEditingController(
      text: widget.response.marksAwarded > 0
          ? widget.response.marksAwarded.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '${widget.index}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.question.questionType.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Max: ${widget.question.marks.toStringAsFixed(0)} marks',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Question
            QuestionWidget(
              question: widget.question,
              currentResponse: widget.response.response,
              readOnly: true,
              showCorrectAnswer: false,
            ),
            const SizedBox(height: 16),
            // Student's answer display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student\'s Answer:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getAnswerText(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grading controls
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _marksController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Award Marks',
                      border: const OutlineInputBorder(),
                      suffixText:
                          '/ ${widget.question.marks.toStringAsFixed(0)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    final marks =
                        double.tryParse(_marksController.text) ?? 0;
                    final maxMarks = widget.question.marks;
                    final clampedMarks = marks.clamp(0, maxMarks);
                    final isCorrect = clampedMarks > 0;
                    widget.onGrade(clampedMarks.toDouble(), isCorrect);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Grade'),
                ),
              ],
            ),
            // Quick grade buttons
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _QuickGradeChip(
                  label: 'Full',
                  onTap: () {
                    _marksController.text =
                        widget.question.marks.toStringAsFixed(0);
                    widget.onGrade(widget.question.marks, true);
                  },
                ),
                _QuickGradeChip(
                  label: 'Half',
                  onTap: () {
                    final half = widget.question.marks / 2;
                    _marksController.text = half.toStringAsFixed(1);
                    widget.onGrade(half, true);
                  },
                ),
                _QuickGradeChip(
                  label: 'Zero',
                  onTap: () {
                    _marksController.text = '0';
                    widget.onGrade(0, false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getAnswerText() {
    final resp = widget.response.response;
    if (resp == null) return 'No answer provided';
    if (resp is Map) {
      return resp['value']?.toString() ?? resp.toString();
    }
    return resp.toString();
  }
}

class _QuickGradeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickGradeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
