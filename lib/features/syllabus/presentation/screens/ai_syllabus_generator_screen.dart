import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/syllabus_ai_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../widgets/ai_generation_preview.dart';

class AISyllabusGeneratorScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String classId;
  final String academicYearId;
  final String? subjectName;
  final String? className;

  const AISyllabusGeneratorScreen({
    super.key,
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
    this.subjectName,
    this.className,
  });

  @override
  ConsumerState<AISyllabusGeneratorScreen> createState() =>
      _AISyllabusGeneratorScreenState();
}

class _AISyllabusGeneratorScreenState
    extends ConsumerState<AISyllabusGeneratorScreen> {
  final _boardController = TextEditingController();
  final _textbookController = TextEditingController();
  String _selectedBoard = 'CBSE';

  final _boards = ['CBSE', 'ICSE', 'State Board', 'IB', 'Other'];

  @override
  void dispose() {
    _boardController.dispose();
    _textbookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(syllabusAIProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Syllabus Generator'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context, aiState),
    );
  }

  Widget _buildBody(BuildContext context, SyllabusAIState aiState) {
    switch (aiState.status) {
      case AIGenerationStatus.idle:
      case AIGenerationStatus.error:
        return _buildInputStep(context, aiState);
      case AIGenerationStatus.generating:
        return _buildLoadingStep();
      case AIGenerationStatus.preview:
        return _buildPreviewStep(context, aiState);
      case AIGenerationStatus.saving:
        return _buildSavingStep();
      case AIGenerationStatus.saved:
        return _buildSuccessStep(context);
    }
  }

  Widget _buildInputStep(BuildContext context, SyllabusAIState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate Syllabus with AI',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI will create a structured syllabus for ${widget.subjectName ?? 'your subject'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Board / Curriculum',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _boards.map((board) {
              final isSelected = _selectedBoard == board;
              return ChoiceChip(
                label: Text(board),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedBoard = board);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Textbook Name (Optional)',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textbookController,
            decoration: InputDecoration(
              hintText: 'e.g., NCERT Mathematics Class 10',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (aiState.status == AIGenerationStatus.error &&
              aiState.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiState.errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Syllabus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Generating syllabus structure...',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(BuildContext context, SyllabusAIState aiState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.preview, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Preview Generated Syllabus',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: AIGenerationPreview(
            tree: aiState.generatedTree,
            onRemoveNode: (unitIdx, chapterIdx, topicIdx) {
              ref.read(syllabusAIProvider.notifier).removePreviewNode(
                    unitIdx,
                    chapterIdx,
                    topicIdx,
                  );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(syllabusAIProvider.notifier).reset();
                  },
                  child: const Text('Regenerate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Syllabus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavingStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.success),
          SizedBox(height: 24),
          Text('Saving syllabus topics...'),
        ],
      ),
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 64),
          const SizedBox(height: 16),
          Text(
            'Syllabus Created!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI-generated syllabus has been saved.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(syllabusAIProvider.notifier).reset();
              // Invalidate the tree so it reloads
              ref.invalidate(syllabusTreeProvider);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Syllabus'),
          ),
        ],
      ),
    );
  }

  void _generate() {
    ref.read(syllabusAIProvider.notifier).generateSyllabus(
          subjectName: widget.subjectName ?? 'Subject',
          className: widget.className ?? 'Class',
          board: _selectedBoard,
          textbookName: _textbookController.text.isNotEmpty
              ? _textbookController.text
              : null,
        );
  }

  void _save() {
    ref.read(syllabusAIProvider.notifier).saveGeneratedTopics(
          subjectId: widget.subjectId,
          classId: widget.classId,
          academicYearId: widget.academicYearId,
        );
  }
}
