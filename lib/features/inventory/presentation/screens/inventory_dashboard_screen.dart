import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/maintenance_calendar.dart';
import '../widgets/stock_level_indicator.dart';

class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(inventoryStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Asset QR',
            onPressed: () => context.push('/inventory/scan'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'categories',
                child: ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Categories'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'purchase_requests',
                child: ListTile(
                  leading: Icon(Icons.shopping_cart_outlined),
                  title: Text('Purchase Requests'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'audits',
                child: ListTile(
                  leading: Icon(Icons.fact_check_outlined),
                  title: Text('Asset Audits'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              context.push('/inventory/$value');
            },
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _DashboardContent(stats: stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load stats: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(inventoryStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/assets/form'),
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusCounts =
        stats['status_counts'] as Map<String, int>? ?? {};
    final totalAssets = stats['total_assets'] as int? ?? 0;
    final totalPurchaseValue =
        (stats['total_purchase_value'] as num?)?.toDouble() ?? 0;
    final totalCurrentValue =
        (stats['total_current_value'] as num?)?.toDouble() ?? 0;
    final depreciationTotal =
        (stats['depreciation_total'] as num?)?.toDouble() ?? 0;
    final lowStockCount = stats['low_stock_items'] as int? ?? 0;
    final pendingMaintenance = stats['pending_maintenance'] as int? ?? 0;
    final maintenanceDue =
        stats['maintenance_due'] as List<AssetMaintenance>? ?? [];
    final lowStockList =
        stats['low_stock_list'] as List<InventoryItem>? ?? [];

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview stat cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                GlassStatCard(
                  title: 'Total Assets',
                  value: '$totalAssets',
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.primary,
                  gradient: AppColors.primaryGradient,
                  onTap: () => context.push('/inventory/assets'),
                ),
                GlassStatCard(
                  title: 'Total Value',
                  value: _formatCurrency(totalCurrentValue),
                  icon: Icons.account_balance_outlined,
                  iconColor: AppColors.secondary,
                  gradient: AppColors.secondaryGradient,
                  subtitle:
                      'Purchase: ${_formatCurrency(totalPurchaseValue)}',
                ),
                GlassStatCard(
                  title: 'Low Stock Items',
                  value: '$lowStockCount',
                  icon: Icons.warning_amber_rounded,
                  iconColor: lowStockCount > 0
                      ? AppColors.warning
                      : AppColors.success,
                  onTap: () => context.push('/inventory/stock'),
                ),
                GlassStatCard(
                  title: 'Maintenance Due',
                  value: '$pendingMaintenance',
                  icon: Icons.build_outlined,
                  iconColor: pendingMaintenance > 0
                      ? AppColors.warning
                      : AppColors.success,
                  onTap: () => context.push('/inventory/maintenance'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Asset Status Breakdown
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asset Status Breakdown',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusBreakdownRow(
                    label: 'Available',
                    count: statusCounts['available'] ?? 0,
                    total: totalAssets,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  _StatusBreakdownRow(
                    label: 'In Use',
                    count: statusCounts['in_use'] ?? 0,
                    total: totalAssets,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 8),
                  _StatusBreakdownRow(
                    label: 'Maintenance',
                    count: statusCounts['maintenance'] ?? 0,
                    total: totalAssets,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  _StatusBreakdownRow(
                    label: 'Damaged',
                    count: statusCounts['damaged'] ?? 0,
                    total: totalAssets,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 8),
                  _StatusBreakdownRow(
                    label: 'Disposed / Lost',
                    count: (statusCounts['disposed'] ?? 0) +
                        (statusCounts['lost'] ?? 0),
                    total: totalAssets,
                    color: AppColors.textTertiaryLight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Depreciation Summary
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Depreciation Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DepreciationStat(
                          label: 'Purchase Value',
                          value: _formatCurrency(totalPurchaseValue),
                          color: AppColors.info,
                        ),
                      ),
                      Expanded(
                        child: _DepreciationStat(
                          label: 'Current Value',
                          value: _formatCurrency(totalCurrentValue),
                          color: AppColors.success,
                        ),
                      ),
                      Expanded(
                        child: _DepreciationStat(
                          label: 'Depreciation',
                          value: _formatCurrency(depreciationTotal),
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickActionCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Assets',
                    color: AppColors.primary,
                    onTap: () => context.push('/inventory/assets'),
                  ),
                  _QuickActionCard(
                    icon: Icons.category_outlined,
                    label: 'Consumables',
                    color: AppColors.secondary,
                    onTap: () => context.push('/inventory/stock'),
                  ),
                  _QuickActionCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    color: AppColors.accent,
                    onTap: () => context.push('/inventory/scan'),
                  ),
                  _QuickActionCard(
                    icon: Icons.assignment_outlined,
                    label: 'Assign',
                    color: AppColors.info,
                    onTap: () => context.push('/inventory/assets'),
                  ),
                  _QuickActionCard(
                    icon: Icons.build_outlined,
                    label: 'Maintenance',
                    color: AppColors.warning,
                    onTap: () => context.push('/inventory/maintenance'),
                  ),
                  _QuickActionCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Transactions',
                    color: AppColors.adminColor,
                    onTap: () => context.push('/inventory/transactions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Maintenance Calendar
            if (maintenanceDue.isNotEmpty)
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: MaintenanceCalendar(
                  maintenanceList: maintenanceDue,
                  onViewAll: () =>
                      context.push('/inventory/maintenance'),
                ),
              ),
            if (maintenanceDue.isNotEmpty) const SizedBox(height: 16),

            // Low Stock Alerts
            if (lowStockList.isNotEmpty)
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Low Stock Alerts',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push('/inventory/stock'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...lowStockList.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StockLevelChip(item: item),
                              ],
                            ),
                            const SizedBox(height: 6),
                            StockLevelIndicator(
                                item: item, showLabels: false, height: 6),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '\u20B9${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '\u20B9${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '\u20B9${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\u20B9${amount.toStringAsFixed(0)}';
  }
}

class _StatusBreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusBreakdownRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DepreciationStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DepreciationStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label.contains('Purchase')
                ? Icons.shopping_bag_outlined
                : label.contains('Current')
                    ? Icons.trending_up
                    : Icons.trending_down,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiaryLight,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 85,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
