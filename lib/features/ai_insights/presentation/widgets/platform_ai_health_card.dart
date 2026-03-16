import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/platform_ai_stats_provider.dart';

/// AI-generated platform health card for the super admin dashboard.
///
/// Takes platform stats as input and renders a narrative summary.
class PlatformAIHealthCard extends ConsumerWidget {
  final int tenantCount;
  final int totalUsers;

  const PlatformAIHealthCard({
    super.key,
    required this.tenantCount,
    required this.totalUsers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final stats = PlatformStats(
      tenantCount: tenantCount,
      totalStudents: totalUsers,
      activePercent: totalUsers > 0 ? 75.0 : 0,
      monthlyRevenue: 0,
    );

    final narrativeAsync = ref.watch(platformHealthNarrativeProvider(stats));

    return narrativeAsync.when(
      loading: () => _buildCard(context, theme, isLoading: true),
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform AI Health',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isLLMGenerated
                          ? 'AI-generated summary'
                          : 'Platform overview',
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
              'Add tenants to see platform health insights.',
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
          width: 180,
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
