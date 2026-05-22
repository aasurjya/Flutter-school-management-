import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Standard section header used inside dashboards.
///
/// Replaces the inline "Section: 'Management Tools' / EdgeInsets.symmetric…"
/// blocks repeated 4× per dashboard. Pairs with [DashboardSection] for
/// consistent spacing.
class DashboardSectionHeader extends StatelessWidget {
  final String label;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const DashboardSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
          ),
          if (trailing != null)
            InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Text(
                  trailing!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wraps a labeled section + content + consistent vertical rhythm. Use as
/// a `SliverToBoxAdapter` inside a dashboard's `CustomScrollView`.
///
/// ```dart
/// SliverToBoxAdapter(
///   child: DashboardSection(
///     label: 'Management Tools',
///     child: _QuickActionsGrid(...),
///   ),
/// ),
/// ```
class DashboardSection extends StatelessWidget {
  final String label;
  final Widget child;
  final String? trailingAction;
  final VoidCallback? onTrailingTap;
  final EdgeInsets contentPadding;

  /// Vertical spacing above this section (after the previous one).
  final double topGap;

  const DashboardSection({
    super.key,
    required this.label,
    required this.child,
    this.trailingAction,
    this.onTrailingTap,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 12, 24, 0),
    this.topGap = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topGap),
        DashboardSectionHeader(
          label: label,
          trailing: trailingAction,
          onTrailingTap: onTrailingTap,
        ),
        Padding(padding: contentPadding, child: child),
      ],
    );
  }
}

/// Compact KPI tile — used inside metric grids on every dashboard. Replaces
/// 30-line hand-rolled `Container + BoxDecoration + Column` chunks.
class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? trend;
  final VoidCallback? onTap;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? AppColors.primary;
    final body = Container(
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
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Text(
              trend!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: body,
      ),
    );
  }
}
