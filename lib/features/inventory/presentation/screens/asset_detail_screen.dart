import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/asset_qr_widget.dart';
import '../widgets/depreciation_chart.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(assetByIdProvider(assetId));
    final assignmentHistoryAsync =
        ref.watch(assetAssignmentHistoryProvider(assetId));
    final depreciationAsync =
        ref.watch(assetDepreciationProvider(assetId));
    final maintenanceAsync = ref.watch(maintenanceRecordsProvider(
        MaintenanceFilter(assetId: assetId)));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      body: assetAsync.when(
        data: (asset) {
          if (asset == null) {
            return const Center(child: Text('Asset not found'));
          }
          return CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: () =>
                        context.push('/inventory/assets/edit/$assetId'),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'assign',
                        child: ListTile(
                          leading: Icon(Icons.person_add_outlined),
                          title: Text('Assign'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'maintenance',
                        child: ListTile(
                          leading: Icon(Icons.build_outlined),
                          title: Text('Schedule Maintenance'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'qr',
                        child: ListTile(
                          leading: Icon(Icons.qr_code),
                          title: Text('Show QR Code'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: Colors.red),
                          title: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) =>
                        _handleAction(context, ref, asset, value),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    asset.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  background: asset.imageUrl != null
                      ? Image.network(
                          asset.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(asset),
                        )
                      : _buildPlaceholder(asset),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and condition row
                      Row(
                        children: [
                          _StatusChip(
                            label: asset.statusDisplay,
                            color: _statusColor(asset.status),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Condition: ${asset.conditionDisplay}',
                            color: _conditionColor(asset.condition),
                          ),
                          const Spacer(),
                          AssetQrMiniWidget(
                            qrData: asset.qrCodeData ??
                                'ASSET:${asset.tenantId}:${asset.assetCode}',
                            size: 48,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Details section
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asset Details',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Divider(height: 24),
                            _DetailRow('Asset Code', asset.assetCode),
                            _DetailRow(
                                'Category',
                                asset.category?.name ??
                                    'Uncategorized'),
                            if (asset.serialNumber != null)
                              _DetailRow(
                                  'Serial Number', asset.serialNumber!),
                            if (asset.description != null)
                              _DetailRow(
                                  'Description', asset.description!),
                            if (asset.location != null)
                              _DetailRow('Location', asset.location!),
                            if (asset.vendor != null)
                              _DetailRow('Vendor', asset.vendor!),
                            if (asset.assignedToName != null)
                              _DetailRow(
                                  'Assigned To', asset.assignedToName!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Financial section
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Information',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Divider(height: 24),
                            if (asset.purchaseDate != null)
                              _DetailRow('Purchase Date',
                                  dateFormat.format(asset.purchaseDate!)),
                            if (asset.purchasePrice != null)
                              _DetailRow('Purchase Price',
                                  '\u20B9${asset.purchasePrice!.toStringAsFixed(2)}'),
                            if (asset.currentValue != null)
                              _DetailRow('Current Value',
                                  '\u20B9${asset.currentValue!.toStringAsFixed(2)}'),
                            if (asset.purchasePrice != null &&
                                asset.currentValue != null)
                              _DetailRow(
                                'Depreciation',
                                '${asset.depreciationPercentage.toStringAsFixed(1)}% (\u20B9${asset.depreciationAmount.toStringAsFixed(2)})',
                              ),
                            if (asset.warrantyExpiry != null)
                              _DetailRow(
                                'Warranty',
                                '${dateFormat.format(asset.warrantyExpiry!)} ${asset.isUnderWarranty ? "(Active)" : "(Expired)"}',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Specifications
                      if (asset.specifications.isNotEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Specifications',
                                style:
                                    theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Divider(height: 24),
                              ...asset.specifications.entries.map(
                                (entry) => _DetailRow(
                                  entry.key,
                                  entry.value.toString(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (asset.specifications.isNotEmpty)
                        const SizedBox(height: 16),

                      // Depreciation Chart
                      depreciationAsync.when(
                        data: (data) {
                          if (data.isEmpty) return const SizedBox.shrink();
                          return GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: DepreciationChart(
                              depreciationData: data,
                              purchasePrice: asset.purchasePrice,
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // Assignment History
                      Text(
                        'Assignment History',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      assignmentHistoryAsync.when(
                        data: (assignments) {
                          if (assignments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No assignment history',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: assignments.map((a) {
                              return Card(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _assignStatusColor(a.status)
                                            .withValues(alpha: 0.1),
                                    child: Icon(
                                      a.status ==
                                              AssignmentStatus.returned
                                          ? Icons.assignment_return
                                          : Icons.person,
                                      color:
                                          _assignStatusColor(a.status),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                      a.assignedToName ?? 'Unknown'),
                                  subtitle: Text(
                                    '${dateFormat.format(a.assignedDate)}'
                                    '${a.returnDate != null ? " - ${dateFormat.format(a.returnDate!)}" : " - Present"}',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _assignStatusColor(
                                              a.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      a.status.label,
                                      style: theme
                                          .textTheme.labelSmall
                                          ?.copyWith(
                                        color: _assignStatusColor(
                                            a.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (error, _) =>
                            Text('Error loading assignments: $error'),
                      ),
                      const SizedBox(height: 16),

                      // Maintenance History
                      Text(
                        'Maintenance History',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      maintenanceAsync.when(
                        data: (records) {
                          if (records.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No maintenance records',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: records.map((m) {
                              return Card(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _maintStatusColor(m.status)
                                            .withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.build_outlined,
                                      color:
                                          _maintStatusColor(m.status),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                      m.maintenanceType.label),
                                  subtitle: Text(
                                    '${dateFormat.format(m.scheduledDate)}'
                                    '${m.cost > 0 ? " - \u20B9${m.cost.toStringAsFixed(0)}" : ""}',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _maintStatusColor(
                                              m.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      m.status.label,
                                      style: theme
                                          .textTheme.labelSmall
                                          ?.copyWith(
                                        color: _maintStatusColor(
                                            m.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (error, _) =>
                            Text('Error loading maintenance: $error'),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPlaceholder(Asset asset) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Color _statusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.available:
        return AppColors.success;
      case AssetStatus.inUse:
        return AppColors.info;
      case AssetStatus.maintenance:
        return AppColors.warning;
      case AssetStatus.damaged:
        return AppColors.error;
      case AssetStatus.disposed:
        return AppColors.textTertiaryLight;
      case AssetStatus.lost:
        return AppColors.error;
    }
  }

  Color _conditionColor(AssetCondition condition) {
    switch (condition) {
      case AssetCondition.excellent:
        return AppColors.success;
      case AssetCondition.good:
        return AppColors.info;
      case AssetCondition.fair:
        return AppColors.warning;
      case AssetCondition.poor:
        return AppColors.error;
    }
  }

  Color _assignStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return AppColors.info;
      case AssignmentStatus.returned:
        return AppColors.success;
      case AssignmentStatus.overdue:
        return AppColors.error;
    }
  }

  Color _maintStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.scheduled:
        return AppColors.info;
      case MaintenanceStatus.inProgress:
        return AppColors.warning;
      case MaintenanceStatus.completed:
        return AppColors.success;
      case MaintenanceStatus.cancelled:
        return AppColors.textTertiaryLight;
    }
  }

  void _handleAction(
      BuildContext context, WidgetRef ref, Asset asset, String action) {
    switch (action) {
      case 'assign':
        context.push('/inventory/assign?assetId=${asset.id}');
        break;
      case 'maintenance':
        context.push('/inventory/maintenance/new?assetId=${asset.id}');
        break;
      case 'qr':
        _showQrDialog(context, asset);
        break;
      case 'delete':
        _confirmDelete(context, ref, asset);
        break;
    }
  }

  void _showQrDialog(BuildContext context, Asset asset) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AssetQrWidget(asset: asset),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Asset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset?'),
        content: Text(
            'Are you sure you want to delete "${asset.name}" (${asset.assetCode})? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(inventoryRepositoryProvider);
                await repo.deleteAsset(asset.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Asset deleted')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
