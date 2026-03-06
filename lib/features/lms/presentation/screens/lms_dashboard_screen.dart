import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/lms_provider.dart';
import '../widgets/course_card.dart';

class LmsDashboardScreen extends ConsumerWidget {
  const LmsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(lmsStatsProvider);
    final enrollmentsAsync = ref.watch(allMyEnrollmentsProvider);
    final publishedAsync = ref.watch(
      publishedCoursesProvider(const CatalogFilter(limit: 5)),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Browse Courses',
            onPressed: () => context.push(AppRoutes.lmsCatalog),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(lmsStatsProvider);
          ref.invalidate(allMyEnrollmentsProvider);
          ref.invalidate(publishedCoursesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            statsAsync.when(
              data: (stats) => _buildStatsRow(context, stats),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading stats: $e'),
              ),
            ),
            const SizedBox(height: 20),

            // Continue learning
            enrollmentsAsync.when(
              data: (enrollments) {
                final inProgress = enrollments
                    .where((e) =>
                        e.status == EnrollmentStatus.inProgress ||
                        e.status == EnrollmentStatus.enrolled)
                    .toList();
                if (inProgress.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Continue Learning',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.lmsMyCourses),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...inProgress.take(3).map((enrollment) {
                      return CourseCard(
                        course: enrollment.course ??
                            Course(
                              id: enrollment.courseId,
                              tenantId: enrollment.tenantId,
                              title: enrollment.courseName ?? 'Course',
                              teacherId: '',
                              status: CourseStatus.published,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                        progressPercentage: enrollment.progressPercentage,
                        onTap: () => context.push(
                          AppRoutes.lmsCourseProgress.replaceAll(
                              ':enrollmentId', enrollment.id),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Recommended / Browse courses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Courses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.lmsCatalog),
                  child: const Text('Browse All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            publishedAsync.when(
              data: (courses) => courses.isEmpty
                  ? GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.school_outlined,
                                size: 48,
                                color: AppColors.textTertiaryLight),
                            const SizedBox(height: 12),
                            Text(
                              'No courses available yet',
                              style:
                                  theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: courses
                          .map((course) => CourseCard(
                                course: course,
                                onTap: () => context.push(
                                  AppRoutes.lmsCourseDetail
                                      .replaceAll(':courseId', course.id),
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.lmsCourseBuilder),
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, LmsStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        GlassStatCard(
          title: 'Enrolled',
          value: '${stats.totalEnrollments}',
          icon: Icons.school_outlined,
          iconColor: AppColors.primary,
        ),
        GlassStatCard(
          title: 'Completed',
          value: '${stats.completedEnrollments}',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
        ),
        GlassStatCard(
          title: 'In Progress',
          value: '${stats.inProgressEnrollments}',
          icon: Icons.play_circle_outline,
          iconColor: AppColors.warning,
        ),
        GlassStatCard(
          title: 'Certificates',
          value: '${stats.totalCertificates}',
          icon: Icons.workspace_premium_outlined,
          iconColor: AppColors.accent,
        ),
      ],
    );
  }
}
