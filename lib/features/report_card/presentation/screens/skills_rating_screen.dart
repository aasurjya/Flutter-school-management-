import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card_full.dart';
import '../../providers/report_card_provider.dart';

class SkillsRatingScreen extends ConsumerStatefulWidget {
  final String reportId;

  const SkillsRatingScreen({super.key, required this.reportId});

  @override
  ConsumerState<SkillsRatingScreen> createState() =>
      _SkillsRatingScreenState();
}

class _SkillsRatingScreenState extends ConsumerState<SkillsRatingScreen> {
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};
  bool _isSaving = false;
  bool _initialized = false;

  static const _skillCategories = [
    ('leadership', 'Leadership', Icons.military_tech, 'Ability to lead, motivate peers, and take initiative'),
    ('teamwork', 'Teamwork', Icons.groups, 'Collaborative skills and ability to work with others'),
    ('communication', 'Communication', Icons.chat, 'Verbal and written expression clarity'),
    ('creativity', 'Creativity', Icons.lightbulb, 'Innovative thinking and artistic expression'),
    ('critical_thinking', 'Critical Thinking', Icons.psychology, 'Analytical reasoning and problem-solving'),
    ('time_management', 'Time Management', Icons.schedule, 'Punctuality, planning, and task completion'),
  ];

  @override
  void initState() {
    super.initState();
    for (final (key, _, _, _) in _skillCategories) {
      _ratings[key] = 3; // Default rating
      _commentControllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadExistingSkills(List<ReportCardSkill> skills) {
    if (_initialized) return;
    _initialized = true;
    for (final skill in skills) {
      _ratings[skill.skillCategory] = skill.rating;
      _commentControllers[skill.skillCategory]?.text =
          skill.comments ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(rcByIdProvider(widget.reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Skills'),
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
            label: const Text('Save'),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }
          _loadExistingSkills(report.skills);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Student info
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.studentDisplayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(report.classSection,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rating Legend
              const GlassCard(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RatingLabel(1, 'Needs\nImprovement', AppColors.error),
                    _RatingLabel(2, 'Below\nAverage', AppColors.warning),
                    _RatingLabel(3, 'Average', Colors.grey),
                    _RatingLabel(4, 'Good', AppColors.info),
                    _RatingLabel(5, 'Excellent', AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Skill Cards
              ..._skillCategories.map((entry) {
                final (key, label, icon, desc) = entry;
                return _SkillRatingCard(
                  key: ValueKey(key),
                  skillKey: key,
                  label: label,
                  icon: icon,
                  description: desc,
                  rating: _ratings[key] ?? 3,
                  commentController: _commentControllers[key]!,
                  onRatingChanged: (rating) {
                    setState(() => _ratings[key] = rating);
                  },
                );
              }),
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
      final skills = _skillCategories.map((entry) {
        final (key, _, _, _) = entry;
        return {
          'skill_category': key,
          'rating': _ratings[key] ?? 3,
          'comments': _commentControllers[key]?.text.trim(),
        };
      }).toList();

      await repo.bulkUpsertSkills(widget.reportId, skills);
      ref.invalidate(rcByIdProvider(widget.reportId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skills saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RatingLabel extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _RatingLabel(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _SkillRatingCard extends StatefulWidget {
  final String skillKey;
  final String label;
  final IconData icon;
  final String description;
  final int rating;
  final TextEditingController commentController;
  final ValueChanged<int> onRatingChanged;

  const _SkillRatingCard({
    super.key,
    required this.skillKey,
    required this.label,
    required this.icon,
    required this.description,
    required this.rating,
    required this.commentController,
    required this.onRatingChanged,
  });

  @override
  State<_SkillRatingCard> createState() => _SkillRatingCardState();
}

class _SkillRatingCardState extends State<_SkillRatingCard> {
  bool _showComment = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _ratingColor(widget.rating)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon,
                    color: _ratingColor(widget.rating), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.description,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showComment ? Icons.comment : Icons.comment_outlined,
                  size: 20,
                  color: _showComment ? AppColors.primary : Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _showComment = !_showComment),
                tooltip: 'Add comment',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => widget.onRatingChanged(starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Icon(
                        starIndex <= widget.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: starIndex <= widget.rating
                            ? _ratingColor(widget.rating)
                            : Colors.grey[300],
                        size: 36,
                      ),
                      Text(
                        '$starIndex',
                        style: TextStyle(
                          fontSize: 10,
                          color: starIndex <= widget.rating
                              ? _ratingColor(widget.rating)
                              : Colors.grey[400],
                          fontWeight: starIndex == widget.rating
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Rating Label
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _ratingText(widget.rating),
                style: TextStyle(
                  color: _ratingColor(widget.rating),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Comment
          if (_showComment) ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Optional comment...',
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Color _ratingColor(int rating) {
    switch (rating) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return Colors.grey;
      case 4:
        return AppColors.info;
      case 5:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _ratingText(int rating) {
    switch (rating) {
      case 1:
        return 'Needs Improvement';
      case 2:
        return 'Below Average';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
