import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';

class ExamBuilderScreen extends ConsumerStatefulWidget {
  final String? examId;

  const ExamBuilderScreen({super.key, this.examId});

  @override
  ConsumerState<ExamBuilderScreen> createState() => _ExamBuilderScreenState();
}

class _ExamBuilderScreenState extends ConsumerState<ExamBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _passingMarksController = TextEditingController(text: '40');
  final _instructionsController = TextEditingController();

  OnlineExamType _examType = OnlineExamType.classTest;
  String? _subjectId;
  String? _classId;
  ExamSettings _settings = const ExamSettings();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.examId != null) {
      Future.microtask(() {
        ref.read(examBuilderProvider.notifier).loadExam(widget.examId!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _passingMarksController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(examBuilderProvider);

    // Populate form when editing
    if (builderState.exam != null && _titleController.text.isEmpty) {
      _populateForm(builderState.exam!);
    }

    final isEditing = widget.examId != null && builderState.exam != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exam' : 'Create Exam'),
        actions: [
          if (isEditing && builderState.exam!.isDraft)
            TextButton.icon(
              onPressed: builderState.totalQuestions > 0
                  ? () => _publishExam()
                  : null,
              icon: const Icon(Icons.publish),
              label: const Text('Publish'),
            ),
        ],
      ),
      body: builderState.isLoading && builderState.exam == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exam details form
                  _buildExamForm(context),
                  const SizedBox(height: 24),
                  // Sections & Questions (only after exam is created)
                  if (isEditing) ...[
                    _buildSectionsArea(context, builderState),
                    const SizedBox(height: 24),
                    // Summary
                    _buildSummary(context, builderState),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildExamForm(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exam Details',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Exam Title *',
                  hintText: 'e.g., Mathematics Unit Test 1',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<OnlineExamType>(
                initialValue: _examType,
                decoration: const InputDecoration(
                  labelText: 'Exam Type',
                  border: OutlineInputBorder(),
                ),
                items: OnlineExamType.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _examType = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (min) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _passingMarksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Passing Marks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions for Students',
                  hintText: 'Any special instructions...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // Save / Create button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isCreating ? null : _saveExam,
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.examId != null
                          ? 'Update Exam'
                          : 'Create Exam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsArea(
      BuildContext context, ExamBuilderState builderState) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sections & Questions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            FilledButton.tonalIcon(
              onPressed: () => _showAddSectionDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Section'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (builderState.sections.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.view_list_outlined,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No sections yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a section to start adding questions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...builderState.sections.map((section) {
            final questions =
                builderState.sectionQuestions[section.id] ?? [];
            return _SectionCard(
              section: section,
              questions: questions,
              onAddQuestion: () =>
                  _showAddQuestionDialog(section.id),
              onDeleteSection: () => ref
                  .read(examBuilderProvider.notifier)
                  .deleteSection(section.id),
              onDeleteQuestion: (qId) => ref
                  .read(examBuilderProvider.notifier)
                  .deleteQuestion(qId),
            );
          }),
      ],
    );
  }

  Widget _buildSummary(
      BuildContext context, ExamBuilderState builderState) {
    return Card(
      color: AppColors.infoLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              icon: Icons.view_list,
              value: '${builderState.sections.length}',
              label: 'Sections',
            ),
            _SummaryItem(
              icon: Icons.quiz_outlined,
              value: '${builderState.totalQuestions}',
              label: 'Questions',
            ),
            _SummaryItem(
              icon: Icons.grade_outlined,
              value: builderState.totalMarks.toStringAsFixed(0),
              label: 'Total Marks',
            ),
          ],
        ),
      ),
    );
  }

  void _populateForm(OnlineExam exam) {
    _titleController.text = exam.title;
    _descriptionController.text = exam.description ?? '';
    _durationController.text = exam.durationMinutes.toString();
    _passingMarksController.text = exam.passingMarks.toStringAsFixed(0);
    _instructionsController.text = exam.instructions ?? '';
    _examType = exam.examType;
    _subjectId = exam.subjectId;
    _classId = exam.classId;
    _settings = exam.settings;
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'exam_type': _examType.value,
      'duration_minutes': int.tryParse(_durationController.text) ?? 60,
      'passing_marks':
          double.tryParse(_passingMarksController.text) ?? 40,
      'instructions': _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      'settings': _settings.toJson(),
    };

    if (_subjectId != null) data['subject_id'] = _subjectId;
    if (_classId != null) data['class_id'] = _classId;

    if (widget.examId != null) {
      await ref.read(examBuilderProvider.notifier).updateExam(data);
    } else {
      final exam =
          await ref.read(examBuilderProvider.notifier).createExam(data);
      if (exam != null && mounted) {
        context.pushReplacement('/online-exams/builder/${exam.id}');
      }
    }

    setState(() => _isCreating = false);
  }

  void _publishExam() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Exam?'),
        content: const Text(
          'This will schedule the exam and make it visible to students. You can still edit questions until the exam goes live.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(examBuilderProvider.notifier).publishExam();
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _showAddSectionDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: '1');
    final negCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Section'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Section Title *',
                  hintText: 'e.g., Section A - MCQ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: marksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Marks/Q',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: negCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Neg. Marks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              ref.read(examBuilderProvider.notifier).addSection(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    marksPerQuestion:
                        double.tryParse(marksCtrl.text) ?? 1,
                    negativeMarks:
                        double.tryParse(negCtrl.text) ?? 0,
                  );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog(String sectionId) {
    final textCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: '1');
    final explanationCtrl = TextEditingController();
    var questionType = ExamQuestionType.mcq;
    var difficulty = ExamDifficulty.medium;
    final optionControllers = List.generate(
        4, (_) => TextEditingController());
    final correctAnswerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Question'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<ExamQuestionType>(
                    initialValue: questionType,
                    decoration: const InputDecoration(
                      labelText: 'Question Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ExamQuestionType.values
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => questionType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Question Text *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (questionType == ExamQuestionType.mcq ||
                      questionType == ExamQuestionType.multiSelect) ...[
                    ...List.generate(4, (i) {
                      final key = String.fromCharCode(65 + i);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Option $key',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }),
                    TextField(
                      controller: correctAnswerCtrl,
                      decoration: InputDecoration(
                        labelText: questionType == ExamQuestionType.multiSelect
                            ? 'Correct Answers (e.g., A,B)'
                            : 'Correct Answer (e.g., A)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (questionType == ExamQuestionType.trueFalse)
                    DropdownButtonFormField<String>(
                      initialValue: correctAnswerCtrl.text.isEmpty
                          ? null
                          : correctAnswerCtrl.text,
                      decoration: const InputDecoration(
                        labelText: 'Correct Answer',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'true', child: Text('True')),
                        DropdownMenuItem(
                            value: 'false', child: Text('False')),
                      ],
                      onChanged: (v) =>
                          correctAnswerCtrl.text = v ?? '',
                    ),
                  if (questionType == ExamQuestionType.fillBlank)
                    TextField(
                      controller: correctAnswerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correct Answer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: marksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Marks',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ExamDifficulty>(
                          initialValue: difficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                            border: OutlineInputBorder(),
                          ),
                          items: ExamDifficulty.values
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text(d.label)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => difficulty = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: explanationCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Explanation (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);

                final List<dynamic> options = [];
                dynamic correctAnswer;

                if (questionType == ExamQuestionType.mcq ||
                    questionType == ExamQuestionType.multiSelect) {
                  for (int i = 0; i < 4; i++) {
                    if (optionControllers[i].text.trim().isNotEmpty) {
                      options.add({
                        'key': String.fromCharCode(65 + i),
                        'text': optionControllers[i].text.trim(),
                      });
                    }
                  }
                  if (questionType == ExamQuestionType.multiSelect) {
                    correctAnswer = {
                      'values': correctAnswerCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList()
                    };
                  } else {
                    correctAnswer = {
                      'value': correctAnswerCtrl.text.trim()
                    };
                  }
                } else if (questionType == ExamQuestionType.trueFalse ||
                    questionType == ExamQuestionType.fillBlank) {
                  correctAnswer = {
                    'value': correctAnswerCtrl.text.trim()
                  };
                }

                ref.read(examBuilderProvider.notifier).addQuestion(
                  sectionId,
                  {
                    'question_type': questionType.value,
                    'question_text': textCtrl.text.trim(),
                    'options': options,
                    'correct_answer': correctAnswer ?? {},
                    'marks': double.tryParse(marksCtrl.text) ?? 1,
                    'difficulty': difficulty.value,
                    'explanation': explanationCtrl.text.trim().isEmpty
                        ? null
                        : explanationCtrl.text.trim(),
                  },
                );
              },
              child: const Text('Add Question'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SECTION CARD ====================

class _SectionCard extends StatelessWidget {
  final ExamSection section;
  final List<ExamQuestion> questions;
  final VoidCallback onAddQuestion;
  final VoidCallback onDeleteSection;
  final void Function(String) onDeleteQuestion;

  const _SectionCard({
    required this.section,
    required this.questions,
    required this.onAddQuestion,
    required this.onDeleteSection,
    required this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(40),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (section.description != null)
                        Text(
                          section.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        '${questions.length} questions - ${section.marksPerQuestion} marks each',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                        value: 'add', child: Text('Add Question')),
                    const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete Section', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'add') onAddQuestion();
                    if (v == 'delete') onDeleteSection();
                  },
                ),
              ],
            ),
          ),
          // Questions list
          if (questions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: TextButton.icon(
                  onPressed: onAddQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add first question'),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final q = questions[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _difficultyColor(q.difficulty),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    q.questionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    '${q.questionType.label} - ${q.marks.toStringAsFixed(0)} marks',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.error),
                    onPressed: () => onDeleteQuestion(q.id),
                  ),
                );
              },
            ),
          // Add question button at bottom
          if (questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton.icon(
                  onPressed: onAddQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Question'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _difficultyColor(ExamDifficulty d) {
    switch (d) {
      case ExamDifficulty.easy:
        return AppColors.success;
      case ExamDifficulty.medium:
        return AppColors.warning;
      case ExamDifficulty.hard:
        return AppColors.error;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.info, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.info,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
