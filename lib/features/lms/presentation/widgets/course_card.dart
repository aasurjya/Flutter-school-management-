import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final bool showTeacher;
  final double? progressPercentage;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showTeacher = true,
    this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / header
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: _gradientForCourse(course.title),
            ),
            child: Stack(
              children: [
                if (course.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      course.thumbnailUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CourseStatusBadge(status: course.status),
                ),
                // Tags
                if (course.tags.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: course.tags
                          .take(2)
                          .map((tag) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (course.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    course.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                // Meta row
                Row(
                  children: [
                    if (course.subjectName != null) ...[
                      Icon(Icons.book_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        course.subjectName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (course.className != null) ...[
                      Icon(Icons.class_outlined,
                          size: 14,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight),
                      const SizedBox(width: 4),
                      Text(
                        course.className!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (course.isSelfPaced)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Self-paced',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Teacher & module count row
                Row(
                  children: [
                    if (showTeacher && course.teacherName != null) ...[
                      CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            AppColors.teacherColor.withValues(alpha: 0.1),
                        child: Text(
                          course.teacherName![0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.teacherColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          course.teacherName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Icon(Icons.view_module_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight),
                    const SizedBox(width: 4),
                    Text(
                      '${course.modules?.length ?? 0} modules',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                // Progress bar (for enrolled courses)
                if (progressPercentage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercentage! / 100,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressPercentage! >= 100
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${progressPercentage!.toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: progressPercentage! >= 100
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _gradientForCourse(String title) {
    final gradients = [
      AppColors.primaryGradient,
      AppColors.oceanGradient,
      AppColors.forestGradient,
      AppColors.sunriseGradient,
      AppColors.secondaryGradient,
      AppColors.accentGradient,
    ];
    return gradients[title.hashCode.abs() % gradients.length];
  }
}

class _CourseStatusBadge extends StatelessWidget {
  final CourseStatus status;

  const _CourseStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case CourseStatus.published:
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
        break;
      case CourseStatus.draft:
        bgColor = AppColors.warningLight;
        textColor = AppColors.warning;
        break;
      case CourseStatus.archived:
        bgColor = AppColors.errorLight;
        textColor = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
