import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card_full.dart';
import '../../providers/report_card_provider.dart';

class AddCommentsScreen extends ConsumerStatefulWidget {
  final String reportId;

  const AddCommentsScreen({super.key, required this.reportId});

  @override
  ConsumerState<AddCommentsScreen> createState() => _AddCommentsScreenState();
}

class _AddCommentsScreenState extends ConsumerState<AddCommentsScreen> {
  final _classTeacherController = TextEditingController();
  final _principalController = TextEditingController();
  final _subjectTeacherController = TextEditingController();
  final _counselorController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _classTeacherController.dispose();
    _principalController.dispose();
    _subjectTeacherController.dispose();
    _counselorController.dispose();
    super.dispose();
  }

  void _loadExistingComments(List<ReportCardComment> comments) {
    for (final c in comments) {
      switch (c.commentType) {
        case 'class_teacher':
          if (_classTeacherController.text.isEmpty) {
            _classTeacherController.text = c.commentText;
          }
          break;
        case 'principal':
          if (_principalController.text.isEmpty) {
            _principalController.text = c.commentText;
          }
          break;
        case 'subject_teacher':
          if (_subjectTeacherController.text.isEmpty) {
            _subjectTeacherController.text = c.commentText;
          }
          break;
        case 'counselor':
          if (_counselorController.text.isEmpty) {
            _counselorController.text = c.commentText;
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(rcByIdProvider(widget.reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Comments'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveAll,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save All'),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }

          // Load existing comments once
          _loadExistingComments(report.comments);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Student info header
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        (report.studentName ?? 'S')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.studentDisplayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${report.classSection} | ${report.termName ?? ""}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Class Teacher Comment
              _CommentField(
                title: "Class Teacher's Remarks",
                icon: Icons.person,
                color: AppColors.teacherColor,
                controller: _classTeacherController,
                hintText:
                    'Write a personalized comment about the student\'s overall performance, behavior, and areas for improvement...',
                suggestions: _classTeacherSuggestions,
              ),
              const SizedBox(height: 16),

              // Principal Comment
              _CommentField(
                title: "Principal's Remarks",
                icon: Icons.admin_panel_settings,
                color: AppColors.adminColor,
                controller: _principalController,
                hintText:
                    'Write a motivational comment or note from the principal...',
                suggestions: _principalSuggestions,
              ),
              const SizedBox(height: 16),

              // Subject Teacher Comment
              _CommentField(
                title: "Subject Teacher's Remarks",
                icon: Icons.school,
                color: AppColors.info,
                controller: _subjectTeacherController,
                hintText:
                    'Comments about performance in specific subjects...',
                suggestions: const [],
              ),
              const SizedBox(height: 16),

              // Counselor Comment
              _CommentField(
                title: "Counselor's Remarks",
                icon: Icons.psychology,
                color: AppColors.secondary,
                controller: _counselorController,
                hintText:
                    'Behavioral observations and recommendations...',
                suggestions: const [],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(rcFullRepositoryProvider);

      final entries = <MapEntry<String, TextEditingController>>[
        MapEntry('class_teacher', _classTeacherController),
        MapEntry('principal', _principalController),
        MapEntry('subject_teacher', _subjectTeacherController),
        MapEntry('counselor', _counselorController),
      ];

      for (final entry in entries) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          await repo.upsertComment(
            reportCardId: widget.reportId,
            commentType: entry.key,
            commentText: text,
          );
        }
      }

      ref.invalidate(rcByIdProvider(widget.reportId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comments saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving comments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _CommentField extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final TextEditingController controller;
  final String hintText;
  final List<String> suggestions;

  const _CommentField({
    required this.title,
    required this.icon,
    required this.color,
    required this.controller,
    required this.hintText,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Quick suggestions:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions.map((s) {
                return InkWell(
                  onTap: () {
                    if (controller.text.isNotEmpty) {
                      controller.text += ' $s';
                    } else {
                      controller.text = s;
                    }
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

const _classTeacherSuggestions = [
  'Excellent performance throughout the term.',
  'Needs to improve in classroom participation.',
  'Shows great potential and consistent effort.',
  'Should focus more on homework completion.',
  'A well-behaved student with leadership qualities.',
  'Needs to work on time management skills.',
];

const _principalSuggestions = [
  'Keep up the excellent work!',
  'We are proud of your achievements.',
  'Continue striving for excellence.',
  'Wishing you the best for the upcoming term.',
];
