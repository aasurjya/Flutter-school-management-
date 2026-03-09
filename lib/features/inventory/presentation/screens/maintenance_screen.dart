import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  final String? preselectedAssetId;

  const MaintenanceScreen({super.key, this.preselectedAssetId});

  @override
  ConsumerState<MaintenanceScreen> createState() =>
      _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.preselectedAssetId != null) {
      _tabController.index = 1; // Go to create tab
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Schedule'),
            Tab(text: 'New Maintenance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MaintenanceListTab(statusFilter: _statusFilter),
          _NewMaintenanceTab(
            preselectedAssetId: widget.preselectedAssetId,
            onComplete: () {
              _tabController.animateTo(0);
              ref.invalidate(maintenanceRecordsProvider);
              ref.invalidate(maintenanceDueProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _MaintenanceListTab extends ConsumerWidget {
  final String? statusFilter;

  const _MaintenanceListTab({this.statusFilter});

  Color _statusColor(MaintenanceStatus status) {
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

  Color _typeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.preventive:
        return AppColors.info;
      case MaintenanceType.corrective:
        return AppColors.warning;
      case MaintenanceType.emergency:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceAsync = ref.watch(maintenanceRecordsProvider(
      MaintenanceFilter(status: statusFilter),
    ));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return maintenanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_outlined,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No maintenance records',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final m = records[index];
            final statusColor = _statusColor(m.status);
            final typeColor = _typeColor(m.maintenanceType);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              typeColor.withValues(alpha: 0.1),
                          child: Icon(Icons.build_outlined,
                              color: typeColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.asset?.name ??
                                    'Asset #${m.assetId.substring(0, 8)}',
                                style:
                                    theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: typeColor
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.maintenanceType.label,
                                      style: theme
                                          .textTheme.labelSmall
                                          ?.copyWith(
                                        color: typeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.status.label,
                                      style: theme
                                          .textTheme.labelSmall
                                          ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (m.isOverdue)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (m.description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          m.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14,
                            color: AppColors.textTertiaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Scheduled: ${dateFormat.format(m.scheduledDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (m.cost > 0) ...[
                          const Spacer(),
                          Text(
                            '\u20B9${m.cost.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (m.status == MaintenanceStatus.scheduled ||
                        m.status == MaintenanceStatus.inProgress)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            if (m.status ==
                                MaintenanceStatus.scheduled)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _updateStatus(context, ref, m, 'in_progress'),
                                  child: const Text('Start'),
                                ),
                              ),
                            if (m.status ==
                                MaintenanceStatus.scheduled)
                              const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () =>
                                    _updateStatus(context, ref, m, 'completed'),
                                child: const Text('Complete'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref,
      AssetMaintenance m, String status) async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final data = <String, dynamic>{'status': status};
      if (status == 'completed') {
        data['completed_date'] =
            DateTime.now().toIso8601String().split('T')[0];
      }
      await repo.updateMaintenance(m.id, data);
      ref.invalidate(maintenanceRecordsProvider);
      ref.invalidate(maintenanceDueProvider);
      ref.invalidate(assetsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Maintenance ${status.replaceAll("_", " ")}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _NewMaintenanceTab extends ConsumerStatefulWidget {
  final String? preselectedAssetId;
  final VoidCallback onComplete;

  const _NewMaintenanceTab({
    this.preselectedAssetId,
    required this.onComplete,
  });

  @override
  ConsumerState<_NewMaintenanceTab> createState() =>
      _NewMaintenanceTabState();
}

class _NewMaintenanceTabState
    extends ConsumerState<_NewMaintenanceTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAssetId;
  MaintenanceType _maintenanceType = MaintenanceType.corrective;
  final _descriptionController = TextEditingController();
  final _vendorController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _scheduledDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.preselectedAssetId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _vendorController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(
        assetsProvider(const AssetFilter()));
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asset selection
            assetsAsync.when(
              data: (assets) => DropdownButtonFormField<String>(
                initialValue: _selectedAssetId,
                decoration: const InputDecoration(
                  labelText: 'Select Asset *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: assets.map((a) {
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (${a.assetCode})'),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedAssetId = value),
                validator: (v) =>
                    v == null ? 'Select an asset' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading assets'),
            ),
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<MaintenanceType>(
              initialValue: _maintenanceType,
              decoration: const InputDecoration(
                labelText: 'Maintenance Type *',
                prefixIcon: Icon(Icons.build_outlined),
              ),
              items: MaintenanceType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _maintenanceType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Scheduled date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                  'Scheduled: ${dateFormat.format(_scheduledDate)}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDate,
                  firstDate: DateTime.now().subtract(
                      const Duration(days: 30)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _scheduledDate = date);
                }
              },
            ),
            const SizedBox(height: 16),

            // Cost and vendor
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Cost',
                      prefixText: '\u20B9 ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _vendorController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: const Text('Schedule Maintenance'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.createMaintenance({
        'asset_id': _selectedAssetId,
        'maintenance_type': _maintenanceType.value,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        'reported_by': repo.currentUserId,
        'scheduled_date':
            _scheduledDate.toIso8601String().split('T')[0],
        'cost': double.tryParse(_costController.text) ?? 0,
        'vendor': _vendorController.text.isEmpty
            ? null
            : _vendorController.text.trim(),
        'notes': _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        'status': 'scheduled',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance scheduled')),
        );
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
