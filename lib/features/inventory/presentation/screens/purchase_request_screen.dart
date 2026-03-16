import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';

class PurchaseRequestScreen extends ConsumerStatefulWidget {
  const PurchaseRequestScreen({super.key});

  @override
  ConsumerState<PurchaseRequestScreen> createState() =>
      _PurchaseRequestScreenState();
}

class _PurchaseRequestScreenState
    extends ConsumerState<PurchaseRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Purchase Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Requests'),
            Tab(text: 'New Request'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestListTab(statusFilter: _statusFilter),
          _NewRequestTab(
            onComplete: () {
              _tabController.animateTo(0);
              ref.invalidate(purchaseRequestsProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _RequestListTab extends ConsumerWidget {
  final String? statusFilter;

  const _RequestListTab({this.statusFilter});

  Color _statusColor(PurchaseRequestStatus status) {
    switch (status) {
      case PurchaseRequestStatus.draft:
        return AppColors.textSecondaryLight;
      case PurchaseRequestStatus.submitted:
        return AppColors.info;
      case PurchaseRequestStatus.approved:
        return AppColors.success;
      case PurchaseRequestStatus.rejected:
        return AppColors.error;
      case PurchaseRequestStatus.ordered:
        return AppColors.warning;
      case PurchaseRequestStatus.received:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync =
        ref.watch(purchaseRequestsProvider(statusFilter));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No purchase requests',
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
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final pr = requests[index];
            final color = _statusColor(pr.status);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                pr.requestNumber,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'By ${pr.requestedByName ?? "Unknown"}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            pr.status.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.list,
                            size: 16,
                            color: AppColors.textTertiaryLight),
                        const SizedBox(width: 4),
                        Text(
                          '${pr.items.length} item(s)',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '\u20B9${pr.totalEstimatedCost.toStringAsFixed(0)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14,
                            color: AppColors.textTertiaryLight),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(pr.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                        if (pr.vendor != null) ...[
                          const Spacer(),
                          const Icon(Icons.store_outlined,
                              size: 14,
                              color: AppColors.textTertiaryLight),
                          const SizedBox(width: 4),
                          Text(
                            pr.vendor!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (pr.status == PurchaseRequestStatus.submitted)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _updateStatus(context, ref, pr, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () =>
                                    _updateStatus(context, ref, pr, 'approved'),
                                child: const Text('Approve'),
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
      PurchaseRequest pr, String status) async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.updatePurchaseRequest(pr.id, {'status': status});
      ref.invalidate(purchaseRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status')),
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

class _NewRequestTab extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const _NewRequestTab({required this.onComplete});

  @override
  ConsumerState<_NewRequestTab> createState() =>
      _NewRequestTabState();
}

class _NewRequestTabState extends ConsumerState<_NewRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _justificationController = TextEditingController();
  final _vendorController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _justificationController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  double get _totalCost {
    return _items.fold(0.0, (sum, item) {
      return sum +
          ((item['quantity'] as int? ?? 0) *
              (item['estimated_cost'] as double? ?? 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Items list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.borderLight, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Text(
                    'No items added yet. Tap "Add Item" to start.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item['name'] ?? 'Item ${index + 1}'),
                    subtitle: Text(
                      'Qty: ${item['quantity']} x \u20B9${(item['estimated_cost'] as double? ?? 0).toStringAsFixed(0)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\u20B9${((item['quantity'] as int? ?? 0) * (item['estimated_cost'] as double? ?? 0)).toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () =>
                              setState(() => _items.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            if (_items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Estimated Cost',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\u20B9${_totalCost.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            TextFormField(
              controller: _justificationController,
              decoration: const InputDecoration(
                labelText: 'Justification *',
                hintText: 'Why are these items needed?',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              validator: (v) =>
                  v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _vendorController,
              decoration: const InputDecoration(
                labelText: 'Preferred Vendor (optional)',
                prefixIcon: Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading || _items.isEmpty
                        ? null
                        : () => _submit('draft'),
                    child: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading || _items.isEmpty
                        ? null
                        : () => _submit('submitted'),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: costCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Est. Unit Cost',
                      prefixText: '\u20B9 ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _items.add({
                    'name': nameCtrl.text.trim(),
                    'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                    'estimated_cost':
                        double.tryParse(costCtrl.text) ?? 0,
                  });
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String status) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.createPurchaseRequest({
        'items': _items,
        'justification': _justificationController.text.trim(),
        'total_estimated_cost': _totalCost,
        'status': status,
        'vendor': _vendorController.text.isEmpty
            ? null
            : _vendorController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'draft'
                ? 'Draft saved'
                : 'Request submitted'),
          ),
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
