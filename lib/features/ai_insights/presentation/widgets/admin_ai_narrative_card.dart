import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/school_health_provider.dart';

/// AI-generated school health narrative card for the admin dashboard.
///
/// Displays a 3-5 sentence daily summary of school health metrics.
class AdminAINarrativeCard extends ConsumerWidget {
  const AdminAINarrativeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final narrativeAsync = ref.watch(schoolHealthNarrativeProvider);

    return narrativeAsync.when(
      loading: () => _buildCard(
        context,
        theme,
        isLoading: true,
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) => _buildCard(
        context,
        theme,
        narrative: result.text,
        isLLMGenerated: result.isLLMGenerated,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme, {
    String? narrative,
    bool isLoading = false,
    bool isLLMGenerated = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Health Summary',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isLLMGenerated ? 'AI-generated insight' : 'Daily overview',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLLMGenerated)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            _buildShimmer(context)
          else if (narrative != null && narrative.isNotEmpty)
            Text(
              narrative,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: AppColors.textSecondaryLight,
              ),
            )
          else
            Text(
              'No data available yet for today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final shimmerBase = Colors.grey.withValues(alpha: 0.15);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}
