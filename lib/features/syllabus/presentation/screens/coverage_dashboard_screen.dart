import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../widgets/coverage_progress_bar.dart';
import '../widgets/coverage_summary_card.dart';

class CoverageDashboardScreen extends ConsumerWidget {
  const CoverageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final yearAsync = ref.watch(currentAcademicYearProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Syllabus Coverage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.forestGradient,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: yearAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (year) {
                if (year == null || currentUser == null) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No academic year found.')),
                  );
                }

                return _buildTeacherView(context, ref, currentUser.id, year.id);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherView(
    BuildContext context,
    WidgetRef ref,
    String teacherId,
    String academicYearId,
  ) {
    final summariesAsync = ref.watch(
      teacherCoverageProvider(
        (teacherId: teacherId, academicYearId: academicYearId),
      ),
    );

    return summariesAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('Error loading coverage: $e')),
      ),
      data: (summaries) {
        if (summaries.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No syllabus data yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a syllabus from the Syllabus Manager.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Overall stats
        final totalTopics =
            summaries.fold<int>(0, (sum, s) => sum + s.totalTopics);
        final completedTopics =
            summaries.fold<int>(0, (sum, s) => sum + s.completedTopics);
        final inProgressTopics =
            summaries.fold<int>(0, (sum, s) => sum + s.inProgressTopics);
        final skippedTopics =
            summaries.fold<int>(0, (sum, s) => sum + s.skippedTopics);
        final overallPct = totalTopics > 0
            ? (completedTopics / totalTopics * 100).round()
            : 0;

        return SliverList(
          delegate: SliverChildListDelegate([
            // Overall summary card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$overallPct%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: overallPct >= 75
                              ? AppColors.success
                              : overallPct >= 50
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CoverageProgressBar(
                    completed: completedTopics,
                    inProgress: inProgressTopics,
                    notStarted:
                        totalTopics - completedTopics - inProgressTopics - skippedTopics,
                    skipped: skippedTopics,
                    height: 12,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip('Total', totalTopics, Colors.grey),
                      _statChip('Done', completedTopics, AppColors.success),
                      _statChip('Active', inProgressTopics, AppColors.warning),
                      _statChip('Skipped', skippedTopics, Colors.blueGrey),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'By Subject',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Per-subject cards
            ...summaries.map((summary) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CoverageSummaryCard(
                    summary: summary,
                    onTap: () {
                      context.push(
                        '${AppRoutes.syllabusEditor}'
                        '?subjectId=${summary.subjectId}'
                        '&classId=${summary.classId}'
                        '&yearId=${summary.academicYearId}'
                        '&sectionId=${summary.sectionId ?? ''}'
                        '&subjectName=${Uri.encodeComponent(summary.subjectName ?? '')}'
                        '&className=${Uri.encodeComponent(summary.className ?? '')}',
                      );
                    },
                  ),
                )),
            const SizedBox(height: 80),
          ]),
        );
      },
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
