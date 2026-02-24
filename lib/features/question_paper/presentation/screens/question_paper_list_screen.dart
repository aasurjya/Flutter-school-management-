import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/question_paper.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/question_paper_provider.dart';

class QuestionPaperListScreen extends ConsumerStatefulWidget {
  const QuestionPaperListScreen({super.key});

  @override
  ConsumerState<QuestionPaperListScreen> createState() =>
      _QuestionPaperListScreenState();
}

class _QuestionPaperListScreenState
    extends ConsumerState<QuestionPaperListScreen> {
  PaperStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final filter = QuestionPaperFilter(status: _statusFilter);
    final papersAsync = ref.watch(questionPapersProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Papers'),
        actions: [
          PopupMenuButton<PaperStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (val) => setState(() => _statusFilter = val),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Papers'),
              ),
              ...PaperStatus.values.map((s) => PopupMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(s.icon, color: s.color, size: 18),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
      body: papersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load papers', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(questionPapersProvider(filter)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (papers) => papers.isEmpty
            ? _buildEmpty(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: papers.length,
                itemBuilder: (context, i) =>
                    _PaperCard(paper: papers[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.questionPaperCreate),
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Generate Paper'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_outlined,
                size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No Question Papers Yet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Use AI to generate a question paper\nin minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.questionPaperCreate),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Generate with AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final QuestionPaper paper;

  const _PaperCard({required this.paper});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('d MMM yyyy').format(paper.createdAt.toLocal());

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push(
        AppRoutes.questionPaperDetail
            .replaceFirst(':paperId', paper.id),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Status color bar
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: paper.status.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        paper.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (paper.isAiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_fix_high,
                                size: 10, color: AppColors.accent),
                            SizedBox(width: 2),
                            Text('AI',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.accent)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${paper.subjectName ?? "Subject"} • ${paper.className ?? "Class"} • ${paper.examTypeDisplay}',
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(
                        '${paper.totalMarks} marks',
                        Icons.score),
                    const SizedBox(width: 6),
                    _Chip('${paper.durationMinutes} min',
                        Icons.timer_outlined),
                    const SizedBox(width: 6),
                    _Chip(
                      paper.difficulty.label,
                      Icons.signal_cellular_alt,
                      color: paper.difficulty.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      paper.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  paper.status.label,
                  style: TextStyle(
                    color: paper.status.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateStr,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _Chip(this.label, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }
}
