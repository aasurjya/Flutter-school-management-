import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/tenant_ai_usage_provider.dart';

/// MTD AI cost summary for the current tenant — drops into the
/// admin dashboard. Hidden gracefully for super_admin or when the RPC is
/// not yet deployed.
class TenantAiUsageCard extends ConsumerWidget {
  const TenantAiUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(tenantAiUsageProvider);
    return usage.when(
      data: (u) => u == null ? const SizedBox.shrink() : _Body(usage: u),
      loading: () => const _Skeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Body extends StatelessWidget {
  final TenantAiUsage usage;
  const _Body({required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = usage.overBudget
        ? AppColors.error
        : usage.nearBudget
            ? AppColors.warning
            : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text('AI usage this month',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ),
              if (usage.tier != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(usage.tier!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w700,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${usage.usedUsdMtd.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
              if (usage.hasBudget) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ \$${usage.budgetUsd.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (usage.hasBudget) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (usage.usedPctOfBudget / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.grey100,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${usage.usedPctOfBudget.toStringAsFixed(1)}% of monthly budget',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ] else
            Text(
              'No monthly budget set — contact your administrator.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _Stat(label: 'Calls', value: '${usage.callsMtd}'),
              _Stat(
                label: 'Cache hits',
                value: '${usage.cacheHitsMtd}',
              ),
              if (usage.blockedMtd > 0)
                _Stat(
                  label: 'Blocked',
                  value: '${usage.blockedMtd}',
                  emphasize: true,
                ),
            ],
          ),
          if (usage.nearBudget && !usage.overBudget) ...[
            const SizedBox(height: 12),
            const _Banner(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              message: 'Approaching monthly limit — usage may be throttled.',
            ),
          ] else if (usage.overBudget) ...[
            const SizedBox(height: 12),
            const _Banner(
              icon: Icons.block,
              color: AppColors.error,
              message: 'Monthly budget exceeded — new AI calls are blocked.',
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _Stat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.error : AppColors.grey900,
            )),
        const SizedBox(width: 4),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.grey500,
            )),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
