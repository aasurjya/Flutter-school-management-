import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/study_recommendation_provider.dart';

/// Inline AI summary card for the student dashboard.
///
/// Shows top 2 study tips and a strength spotlight from real performance data.
/// Links to the full study recommendations screen.
class StudentAISummaryCard extends ConsumerWidget {
  const StudentAISummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentAsync = ref.watch(currentStudentProvider);

    return studentAsync.when(
      loading: () => const _ShimmerCard(),
      error: (_, __) => const SizedBox.shrink(),
      data: (student) {
        if (student == null) return const SizedBox.shrink();

        final recsAsync = ref.watch(
          studyRecommendationsProvider(student.userId ?? student.id),
        );

        return recsAsync.when(
          loading: () => const _ShimmerCard(),
          error: (_, __) => const SizedBox.shrink(),
          data: (rec) {
            final topTips = rec.recommendations.take(2).toList();
            final strength = rec.recommendations
                .where((r) => r.icon == Icons.star)
                .toList();

            return GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Study Insights',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (rec.isLLMGenerated)
                              Text(
                                'Personalized for you',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (strength.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                strength.first.title
                                    .replaceFirst('Strength: ', ''),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Top 2 tips
                  ...topTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            tip.icon,
                            size: 18,
                            color: tip.priority.color,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tip.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tip.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // View all link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.studyRecommendations),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View full plan'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final shimmerBase = Colors.grey.withValues(alpha: 0.15);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: shimmerBase,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: shimmerBase,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
