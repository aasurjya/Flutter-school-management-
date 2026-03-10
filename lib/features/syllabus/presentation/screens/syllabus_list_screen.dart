import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/academic/providers/academic_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../widgets/coverage_summary_card.dart';

class SyllabusListScreen extends ConsumerWidget {
  const SyllabusListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Syllabus Manager',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, ref, user, academicYearAsync),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue academicYearAsync,
  ) {
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return academicYearAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Failed to load academic year: $error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (year) {
        if (year == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No current academic year configured',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        final coverageAsync = ref.watch(
          teacherCoverageProvider((
            teacherId: user.id,
            academicYearId: year.id,
          )),
        );

        return coverageAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (summaries) {
            if (summaries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No subject assignments found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Subject assignments for ${year.name} will appear here.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summaries.length} Subject${summaries.length != 1 ? 's' : ''} Assigned',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...summaries.map((summary) {
                  return Padding(
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
                          '&subjectName=${Uri.encodeComponent(summary.subjectName ?? 'Subject')}'
                          '&className=${Uri.encodeComponent(summary.className ?? 'Class')}',
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 100),
              ],
            );
          },
        );
      },
    );
  }
}
