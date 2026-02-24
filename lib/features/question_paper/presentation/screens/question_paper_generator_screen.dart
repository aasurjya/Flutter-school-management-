import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/question_paper.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/question_paper_provider.dart';

// ============================================================
// Generator Screen — step 1: configure, step 2: preview after AI
// ============================================================

class QuestionPaperGeneratorScreen extends ConsumerStatefulWidget {
  const QuestionPaperGeneratorScreen({super.key});

  @override
  ConsumerState<QuestionPaperGeneratorScreen> createState() =>
      _QuestionPaperGeneratorScreenState();
}

class _QuestionPaperGeneratorScreenState
    extends ConsumerState<QuestionPaperGeneratorScreen> {
  // Config form state
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController(text: 'Mathematics');
  final _classCtrl = TextEditingController(text: 'Class 10');
  final _boardCtrl = TextEditingController(text: 'CBSE');
  final _topicsCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();

  String _examType = 'unit_test';
  int _totalMarks = 80;
  int _durationMinutes = 180;
  DifficultyLevel _difficulty = DifficultyLevel.medium;

  late QuestionPaperConfig _currentConfig;
  late QuestionPaperGeneratorNotifier _notifier;
  bool _notifierInit = false;

  @override
  void initState() {
    super.initState();
    _rebuildConfig();
  }

  void _rebuildConfig() {
    _currentConfig = QuestionPaperConfig(
      subjectName: _subjectCtrl.text,
      className: _classCtrl.text,
      examType: _examType,
      totalMarks: _totalMarks,
      durationMinutes: _durationMinutes,
      difficulty: _difficulty,
      board: _boardCtrl.text,
      topics: _topicsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      extraInstructions: _extraCtrl.text,
    );
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _classCtrl.dispose();
    _boardCtrl.dispose();
    _topicsCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lazily init notifier once we have the first config
    if (!_notifierInit) {
      _notifier = ref.read(
          questionPaperGeneratorProvider(_currentConfig).notifier);
      _notifierInit = true;
    }

    final state =
        ref.watch(questionPaperGeneratorProvider(_currentConfig));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Paper Generator'),
        leading: BackButton(
          onPressed: () {
            if (state.step == GeneratorStep.preview ||
                state.step == GeneratorStep.error) {
              _notifier.reset();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(GeneratorState state) {
    switch (state.step) {
      case GeneratorStep.configure:
        return _buildConfigForm(state);
      case GeneratorStep.generating:
        return _buildGenerating();
      case GeneratorStep.preview:
        return _buildPreview(state);
      case GeneratorStep.saving:
        return _buildSaving();
      case GeneratorStep.done:
        return _buildDone();
      case GeneratorStep.error:
        return _buildError(state);
    }
  }

  // ==================== CONFIG FORM ====================

  Widget _buildConfigForm(GeneratorState state) {
    final examTypes = {
      'unit_test': 'Unit Test',
      'mid_term': 'Mid Term',
      'final': 'Final Exam',
      'practice': 'Practice Paper',
    };

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.accent.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_fix_high, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Question Paper Generator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configure once. Get a full question paper in seconds.',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Subject & Class'),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Field(
                  controller: _subjectCtrl,
                  label: 'Subject',
                  hint: 'e.g. Mathematics',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _classCtrl,
                  label: 'Class / Grade',
                  hint: 'e.g. Class 10',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _boardCtrl,
                  label: 'Board / Curriculum (optional)',
                  hint: 'e.g. CBSE, ICSE, State Board',
                  isRequired: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Exam Settings'),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exam type
                DropdownButtonFormField<String>(
                  value: _examType,
                  decoration: const InputDecoration(
                    labelText: 'Exam Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  items: examTypes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _examType = v ?? _examType),
                ),
                const SizedBox(height: 16),

                // Marks slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Marks',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_totalMarks',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _totalMarks.toDouble(),
                  min: 20,
                  max: 200,
                  divisions: 36,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _totalMarks = v.round()),
                ),

                // Duration slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Duration',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_durationMinutes ~/ 60}h ${_durationMinutes % 60}m',
                        style: const TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _durationMinutes.toDouble(),
                  min: 30,
                  max: 240,
                  divisions: 21,
                  activeColor: AppColors.info,
                  onChanged: (v) =>
                      setState(() => _durationMinutes = v.round()),
                ),

                // Difficulty chips
                const Text('Difficulty',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: DifficultyLevel.values.map((d) {
                    final selected = _difficulty == d;
                    return ChoiceChip(
                      label: Text(d.label),
                      selected: selected,
                      selectedColor: d.color.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: selected ? d.color : Colors.grey[600],
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) =>
                          setState(() => _difficulty = d),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Topics (optional)'),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: _Field(
              controller: _topicsCtrl,
              label: 'Topics to Include',
              hint:
                  'e.g. Quadratic Equations, Coordinate Geometry (comma-separated)',
              isRequired: false,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Special Instructions (optional)'),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: _Field(
              controller: _extraCtrl,
              label: 'Extra Instructions',
              hint:
                  'e.g. Include 2 case study questions, avoid calculus',
              isRequired: false,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _onGenerate,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generate Question Paper',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _onGenerate() {
    if (!_formKey.currentState!.validate()) return;
    _rebuildConfig();
    _notifier.updateConfig(_currentConfig);
    _notifier.generate();
  }

  // ==================== GENERATING ====================

  Widget _buildGenerating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI is generating your question paper...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take 10-20 seconds',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ==================== PREVIEW ====================

  Widget _buildPreview(GeneratorState state) {
    final titleCtrl = TextEditingController(
      text:
          '${_subjectCtrl.text} ${_classCtrl.text} — ${_examTypeLabel(_examType)}',
    );

    return Column(
      children: [
        // Summary bar
        Container(
          color: AppColors.primary.withValues(alpha: 0.1),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (state.isAiGenerated) ...[
                const Icon(Icons.auto_fix_high,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 4),
                const Text('AI Generated',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(width: 16),
              ],
              Text(
                '${state.totalQuestions} Questions',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                '${state.totalMarksFromSections.toStringAsFixed(0)} Marks',
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: _notifier.reset,
                child: const Text('Regenerate'),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title field
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Paper Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sections preview
              ...state.generatedSections.asMap().entries.map((entry) {
                final si = entry.key;
                final section = entry.value;
                final questions =
                    section['questions'] as List<dynamic>? ?? [];
                return _SectionPreview(
                  sectionIndex: si,
                  section: section,
                  questions: questions,
                );
              }),

              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _onSave(titleCtrl.text, state),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Question Paper',
                      style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  void _onSave(String title, GeneratorState state) async {
    final paper = await _notifier.save(title: title);
    if (paper != null && mounted) {
      context.pushReplacement(
        AppRoutes.questionPaperDetail
            .replaceFirst(':paperId', paper.id),
      );
    }
  }

  String _examTypeLabel(String type) {
    const map = {
      'unit_test': 'Unit Test',
      'mid_term': 'Mid Term',
      'final': 'Final Exam',
      'practice': 'Practice Paper',
    };
    return map[type] ?? type;
  }

  // ==================== SAVING ====================

  Widget _buildSaving() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.success),
          SizedBox(height: 16),
          Text('Saving question paper...'),
        ],
      ),
    );
  }

  // ==================== DONE ====================

  Widget _buildDone() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 72),
          SizedBox(height: 16),
          Text('Question paper saved!',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==================== ERROR ====================

  Widget _buildError(GeneratorState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Generation Failed',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _notifier.reset,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.primary,
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.isRequired = true,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: validator ??
          (isRequired
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null),
    );
  }
}

class _SectionPreview extends StatefulWidget {
  final int sectionIndex;
  final Map<String, dynamic> section;
  final List<dynamic> questions;

  const _SectionPreview({
    required this.sectionIndex,
    required this.section,
    required this.questions,
  });

  @override
  State<_SectionPreview> createState() => _SectionPreviewState();
}

class _SectionPreviewState extends State<_SectionPreview> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final totalMarks = widget.questions.fold<double>(
        0.0, (s, q) => s + ((q['marks'] as num?)?.toDouble() ?? 1.0));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Theme(
        data:
            Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              String.fromCharCode(65 + widget.sectionIndex),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            widget.section['title'] ?? 'Section',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${widget.questions.length} questions • ${totalMarks.toStringAsFixed(0)} marks',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: widget.questions.asMap().entries.map((entry) {
            final qi = entry.key;
            final q = entry.value as Map<String, dynamic>;
            final qType = QuestionType.fromString(
                q['question_type']?.toString() ?? 'mcq');
            final diff = DifficultyLevel.fromString(
                q['difficulty']?.toString() ?? 'medium');

            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${qi + 1}.',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['question_text']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MiniChip(qType.label, AppColors.primary),
                            const SizedBox(width: 4),
                            _MiniChip(diff.label, diff.color),
                            const SizedBox(width: 4),
                            _MiniChip(
                                '${q['marks'] ?? 1} mark${(q['marks'] ?? 1) == 1 ? "" : "s"}',
                                Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
