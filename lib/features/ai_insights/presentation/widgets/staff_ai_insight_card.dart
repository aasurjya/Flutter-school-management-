import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_text_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Generic reusable AI insight card for staff dashboards.
///
/// Parameterized by a [provider] that returns an [AITextResult].
/// Each staff role passes their own role-specific provider.
class StaffAIInsightCard extends ConsumerWidget {
  /// The Riverpod provider that fetches the AI insight.
  final ProviderListenable<AsyncValue<AITextResult>> provider;

  /// Title displayed in the card header.
  final String title;

  /// Icon displayed in the header badge.
  final IconData icon;

  /// Color for the icon badge.
  final Color color;

  const StaffAIInsightCard({
    super.key,
    required this.provider,
    required this.title,
    required this.icon,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resultAsync = ref.watch(provider);

    return resultAsync.when(
      loading: () => _buildCard(context, theme, isLoading: true),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.text.isEmpty) return const SizedBox.shrink();
        return _buildCard(
          context,
          theme,
          narrative: result.text,
          isLLMGenerated: result.isLLMGenerated,
        );
      },
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isLLMGenerated ? 'AI-generated' : 'Auto-generated',
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
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
              'No insight available.',
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
          width: 220,
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
