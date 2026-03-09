import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/lms_provider.dart';
import '../widgets/module_list_widget.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseByIdProvider(courseId));
    final enrollmentAsync = ref.watch(courseEnrollmentProvider(courseId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: courseAsync.when(
        data: (course) {
          if (course == null) {
            return const Center(child: Text('Course not found'));
          }

          return CustomScrollView(
            slivers: [
              // App bar with gradient
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: _gradientForCourse(course.title),
                    ),
                    child: course.thumbnailUrl != null
                        ? Image.network(
                            course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          )
                        : null,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.forum_outlined),
                    tooltip: 'Discussions',
                    onPressed: () => context.push(
                      AppRoutes.lmsDiscussionForum
                          .replaceAll(':courseId', courseId),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Description
                    if (course.description != null) ...[
                      Text(
                        course.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info cards
                    _buildInfoSection(context, course),
                    const SizedBox(height: 16),

                    // Enrollment action
                    enrollmentAsync.when(
                      data: (enrollment) =>
                          _buildEnrollmentAction(context, ref, course, enrollment),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => _buildEnrollmentAction(
                          context, ref, course, null),
                    ),
                    const SizedBox(height: 20),

                    // Modules section
                    Text(
                      'Course Content',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.modules?.length ?? 0} modules | ${course.totalContentCount} items | ${course.totalDurationMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ModuleListWidget(
                      modules: course.modules ?? [],
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error: $e'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(courseByIdProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Course course) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, y');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (course.teacherName != null)
          _InfoChip(
            icon: Icons.person_outline,
            label: course.teacherName!,
          ),
        if (course.subjectName != null)
          _InfoChip(
            icon: Icons.book_outlined,
            label: course.subjectName!,
          ),
        if (course.className != null)
          _InfoChip(
            icon: Icons.class_outlined,
            label: course.className!,
          ),
        if (course.isSelfPaced)
          const _InfoChip(
            icon: Icons.self_improvement,
            label: 'Self-paced',
          ),
        if (course.startDate != null)
          _InfoChip(
            icon: Icons.calendar_today,
            label:
                '${dateFormat.format(course.startDate!)}${course.endDate != null ? " - ${dateFormat.format(course.endDate!)}" : ""}',
          ),
        if (course.enrollmentLimit != null)
          _InfoChip(
            icon: Icons.group_outlined,
            label:
                '${course.enrolledCount ?? 0}/${course.enrollmentLimit} enrolled',
          ),
        if (course.tags.isNotEmpty)
          ...course.tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.primaryLight.withValues(alpha: 0.1),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              )),
      ],
    );
  }

  Widget _buildEnrollmentAction(
    BuildContext context,
    WidgetRef ref,
    Course course,
    CourseEnrollment? enrollment,
  ) {
    if (enrollment != null) {
      if (enrollment.status == EnrollmentStatus.completed) {
        return GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.success.withValues(alpha: 0.5),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course Completed!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '${enrollment.progressPercentage.toStringAsFixed(0)}% completed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.push(
                  AppRoutes.lmsCertificate
                      .replaceAll(':enrollmentId', enrollment.id),
                ),
                child: const Text('Certificate'),
              ),
            ],
          ),
        );
      }

      // In progress
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: enrollment.progressPercentage / 100,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${enrollment.progressPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  AppRoutes.lmsCourseProgress
                      .replaceAll(':enrollmentId', enrollment.id),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue Learning'),
              ),
            ),
          ],
        ),
      );
    }

    // Not enrolled
    final isFull = course.enrollmentLimit != null &&
        (course.enrolledCount ?? 0) >= course.enrollmentLimit!;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isFull
            ? null
            : () async {
                try {
                  final repo = ref.read(lmsRepositoryProvider);
                  await repo.enrollInCourse(courseId);
                  ref.invalidate(courseEnrollmentProvider);
                  ref.invalidate(allMyEnrollmentsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Successfully enrolled!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Enrollment failed: $e')),
                    );
                  }
                }
              },
        icon: Icon(isFull ? Icons.block : Icons.add),
        label: Text(isFull ? 'Course Full' : 'Enroll Now'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  LinearGradient _gradientForCourse(String title) {
    final gradients = [
      AppColors.primaryGradient,
      AppColors.oceanGradient,
      AppColors.forestGradient,
      AppColors.sunriseGradient,
    ];
    return gradients[title.hashCode.abs() % gradients.length];
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.inputFillLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
