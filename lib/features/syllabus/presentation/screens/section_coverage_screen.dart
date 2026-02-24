import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../../data/models/syllabus_topic.dart';
import '../../providers/syllabus_provider.dart';
import '../widgets/coverage_progress_bar.dart';

class SectionCoverageScreen extends ConsumerWidget {
  final String subjectId;
  final String classId;
  final String academicYearId;

  const SectionCoverageScreen({
    super.key,
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsByClassProvider(classId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Section Coverage Comparison',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: sectionsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (sections) {
                if (sections.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No sections found.')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final section = sections[index];
                      return _SectionCoverageCard(
                        sectionId: section.id,
                        sectionName: section.displayName,
                        subjectId: subjectId,
                        classId: classId,
                        academicYearId: academicYearId,
                      );
                    },
                    childCount: sections.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCoverageCard extends ConsumerWidget {
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String classId;
  final String academicYearId;

  const _SectionCoverageCard({
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = SyllabusFilter(
      subjectId: subjectId,
      classId: classId,
      academicYearId: academicYearId,
      sectionId: sectionId,
    );
    final summaryAsync = ref.watch(coverageSummaryProvider(filter));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: summaryAsync.when(
          loading: () => _buildShimmer(),
          error: (e, _) => Text('Error: $e'),
          data: (summary) {
            final total = summary?.totalTopics ?? 0;
            final completed = summary?.completedTopics ?? 0;
            final inProgress = summary?.inProgressTopics ?? 0;
            final skipped = summary?.skippedTopics ?? 0;
            final pct = summary?.coveragePercentage ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sectionName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _pctColor(pct).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pct.round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _pctColor(pct),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CoverageProgressBar(
                  completed: completed,
                  inProgress: inProgress,
                  notStarted: total - completed - inProgress - skipped,
                  skipped: skipped,
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed/$total topics completed  •  ${summary?.totalPeriodsSpent ?? 0} periods spent',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 75) return AppColors.success;
    if (pct >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildShimmer() {
    return const SizedBox(
      height: 60,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
