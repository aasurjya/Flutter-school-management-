import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/dashboard_kpis_provider.dart';

/// Compact strip showing the 5 admin KPIs from `v_my_admin_kpis`
/// (active students, today's attendance %, fees MTD, overdue invoices,
/// at-risk students), with the MV's refresh timestamp.
///
/// **Auto-hides** when `adminKpisProvider` returns null — which happens
/// when:
///   • The caller has no tenant context (super_admin).
///   • Migration 00064 (the dashboard MVs) hasn't been applied yet.
///   • The view is empty (no tenant row).
///
/// This means it's safe to drop into any admin dashboard layout without
/// risking visual regression on pre-migration environments. When the MVs
/// land, the strip silently appears and starts showing the pre-aggregated
/// snapshot instead of the existing 5 separate provider calls.
///
/// Spec:
///   • One row, scrollable horizontally on narrow screens.
///   • Each tile mirrors the look of [KpiTile] from the role-dashboard
///     primitives kit (PR #1) — same border, radius, type scale.
///   • Subtitle on the rightmost edge shows "MV refreshed Nm ago" so a
///     viewer can tell this is the pre-aggregated path, not the live one.
class MvBackedKpiStrip extends ConsumerWidget {
  const MvBackedKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminKpisProvider).valueOrNull;
    if (kpis == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final refreshedAgo = _formatRelative(kpis.refreshedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              const Icon(Icons.bolt_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'School snapshot',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Refreshed $refreshedAgo',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Tile(
                  label: 'Active students',
                  value: '${kpis.activeStudents}',
                  icon: Icons.school_outlined,
                ),
                _Tile(
                  label: 'Today attendance',
                  value: kpis.todayAttendancePct == null
                      ? '—'
                      : '${kpis.todayAttendancePct!.toStringAsFixed(0)}%',
                  icon: Icons.event_available_outlined,
                  accentColor: _attendanceColor(kpis.todayAttendancePct),
                ),
                _Tile(
                  label: 'Fees MTD',
                  value: _formatMoney(kpis.feesCollectedMtd),
                  icon: Icons.account_balance_wallet_outlined,
                  accentColor: AppColors.success,
                ),
                _Tile(
                  label: 'Overdue invoices',
                  value: '${kpis.overdueInvoices}',
                  icon: Icons.warning_amber_rounded,
                  accentColor: kpis.overdueInvoices > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
                _Tile(
                  label: 'At-risk students',
                  value: '${kpis.atRiskStudents}',
                  icon: Icons.error_outline,
                  accentColor: kpis.atRiskStudents > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRelative(DateTime when) {
    final delta = DateTime.now().difference(when);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return DateFormat('d MMM').format(when);
  }

  static String _formatMoney(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static Color _attendanceColor(double? pct) {
    if (pct == null) return AppColors.grey400;
    if (pct >= 90) return AppColors.success;
    if (pct >= 75) return AppColors.warning;
    return AppColors.error;
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const _Tile({
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? AppColors.primary;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
