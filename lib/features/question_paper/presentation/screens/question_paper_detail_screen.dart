import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/question_paper.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/question_paper_provider.dart';

// ============================================================
// Detail / Preview Screen
// ============================================================

class QuestionPaperDetailScreen extends ConsumerWidget {
  final String paperId;

  const QuestionPaperDetailScreen({super.key, required this.paperId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperAsync = ref.watch(questionPaperDetailProvider(paperId));

    return paperAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Question Paper')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (paper) => _PaperDetailView(paper: paper),
    );
  }
}

class _PaperDetailView extends ConsumerStatefulWidget {
  final QuestionPaper paper;
  const _PaperDetailView({required this.paper});

  @override
  ConsumerState<_PaperDetailView> createState() => _PaperDetailViewState();
}

class _PaperDetailViewState extends ConsumerState<_PaperDetailView> {
  bool _showAnswers = false;

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;
    final dateStr =
        DateFormat('d MMMM yyyy').format(paper.createdAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          paper.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Toggle answers
          IconButton(
            icon: Icon(
                _showAnswers ? Icons.visibility_off : Icons.visibility),
            tooltip: _showAnswers ? 'Hide Answers' : 'Show Answers',
            onPressed: () =>
                setState(() => _showAnswers = !_showAnswers),
          ),
          // Status menu
          PopupMenuButton<PaperStatus>(
            icon: Icon(
              paper.status.icon,
              color: paper.status.color,
            ),
            tooltip: 'Change Status',
            onSelected: (status) => _changeStatus(status),
            itemBuilder: (context) => PaperStatus.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(s.icon, color: s.color, size: 18),
                          const SizedBox(width: 8),
                          Text(s.label),
                          if (paper.status == s) ...[
                            const Spacer(),
                            const Icon(Icons.check, size: 16),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Paper',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Header card =====
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + AI badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        paper.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (paper.isAiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_fix_high,
                                size: 14, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text('AI Generated',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Meta row
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                        Icons.school_outlined,
                        paper.subjectName ?? 'Subject',
                        AppColors.primary),
                    _MetaChip(
                        Icons.class_outlined,
                        paper.className ?? 'Class',
                        AppColors.secondary),
                    _MetaChip(Icons.quiz_outlined,
                        paper.examTypeDisplay, AppColors.info),
                    _MetaChip(Icons.score, '${paper.totalMarks} marks',
                        AppColors.success),
                    _MetaChip(Icons.timer_outlined,
                        '${paper.durationMinutes} min', Colors.orange),
                    _MetaChip(
                      Icons.signal_cellular_alt,
                      paper.difficulty.label,
                      paper.difficulty.color,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: paper.status.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(paper.status.icon,
                              size: 14, color: paper.status.color),
                          const SizedBox(width: 4),
                          Text(
                            paper.status.label,
                            style: TextStyle(
                              color: paper.status.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Created $dateStr',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),

                // Stats
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                        '${paper.sections.length}',
                        'Sections'),
                    _Stat(
                        '${paper.totalQuestions}',
                        'Questions'),
                    _Stat(
                        '${paper.totalMarks}',
                        'Total Marks'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===== Instructions =====
          if (paper.instructions != null &&
              paper.instructions!.isNotEmpty) ...[
            const Text('General Instructions',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Text(
                paper.instructions!,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ===== Sections + Questions =====
          ...paper.sections.asMap().entries.map((entry) {
            final si = entry.key;
            final section = entry.value;
            return _SectionView(
              sectionIndex: si,
              section: section,
              showAnswers: _showAnswers,
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _changeStatus(PaperStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(questionPaperRepositoryProvider);
      await repo.updatePaperStatus(widget.paper.id, status);
      ref.invalidate(questionPaperDetailProvider(widget.paper.id));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question Paper?'),
        content: const Text(
            'This action cannot be undone. All questions will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final nav = GoRouter.of(context);
              try {
                final repo = ref.read(questionPaperRepositoryProvider);
                await repo.deleteQuestionPaper(widget.paper.id);
                nav.pop();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ==================== SECTION VIEW ====================

class _SectionView extends StatefulWidget {
  final int sectionIndex;
  final QuestionPaperSection section;
  final bool showAnswers;

  const _SectionView({
    required this.sectionIndex,
    required this.section,
    required this.showAnswers,
  });

  @override
  State<_SectionView> createState() => _SectionViewState();
}

class _SectionViewState extends State<_SectionView> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
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
            widget.section.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.section.questionCount} questions • ${widget.section.totalMarks} marks',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (widget.section.instructions != null)
                Text(
                  widget.section.instructions!,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          children: widget.section.items.map((item) {
            return _QuestionTile(
              item: item,
              showAnswer: widget.showAnswers,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ==================== QUESTION TILE ====================

class _QuestionTile extends StatelessWidget {
  final QuestionPaperItem item;
  final bool showAnswer;

  const _QuestionTile({required this.item, required this.showAnswer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number + text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${item.sequenceOrder}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.questionText,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '[${item.marks.toStringAsFixed(item.marks == item.marks.roundToDouble() ? 0 : 1)}]',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // MCQ Options
          if (item.hasOptions && item.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.options.asMap().entries.map((entry) {
                  final optLabel = item.options[entry.key];
                  final isCorrect = showAnswer &&
                      item.correctAnswer != null &&
                      (item.correctAnswer ==
                              String.fromCharCode(65 + entry.key) ||
                          item.correctAnswer == optLabel);
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: isCorrect
                              ? AppColors.success
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          optLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCorrect
                                ? AppColors.success
                                : null,
                            fontWeight: isCorrect
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Answer key (non-MCQ)
          if (showAnswer &&
              item.correctAnswer != null &&
              !item.hasOptions) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check,
                        color: AppColors.success, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.correctAnswer!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Type / Difficulty chips
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              children: [
                _Chip(item.questionType.label, AppColors.primary),
                const SizedBox(width: 4),
                _Chip(item.difficulty.label, item.difficulty.color),
              ],
            ),
          ),

          const Divider(height: 20, thickness: 0.5),
        ],
      ),
    );
  }
}

// ==================== SMALL HELPERS ====================

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500)),
    );
  }
}
