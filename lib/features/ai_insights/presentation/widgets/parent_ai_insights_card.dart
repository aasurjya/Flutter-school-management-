import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/study_recommendation_provider.dart';

/// AI insights card for the parent dashboard.
///
/// Shows top 2 improvement tips for the selected child and a brief
/// AI-generated sentence summarizing the child's week.
class ParentAIInsightsCard extends ConsumerWidget {
  /// The child's user ID (used to look up student record).
  final String childUserId;

  /// The child's display name.
  final String childName;

  const ParentAIInsightsCard({
    super.key,
    required this.childUserId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recsAsync = ref.watch(studyRecommendationsProvider(childUserId));

    return recsAsync.when(
      loading: () => const _ParentShimmerCard(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rec) {
        final tips = rec.recommendations.take(2).toList();
        if (tips.isEmpty) return const SizedBox.shrink();

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
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Tips for ${childName.split(' ').first}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          rec.isLLMGenerated
                              ? 'Based on recent performance'
                              : 'General recommendations',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tips
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: tip.priority.color,
                          shape: BoxShape.circle,
                        ),
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
            ],
          ),
        );
      },
    );
  }
}

class _ParentShimmerCard extends StatelessWidget {
  const _ParentShimmerCard();

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
                width: 140,
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
            width: 180,
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
