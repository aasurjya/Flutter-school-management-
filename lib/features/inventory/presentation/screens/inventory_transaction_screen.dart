import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';

class InventoryTransactionScreen extends ConsumerStatefulWidget {
  const InventoryTransactionScreen({super.key});

  @override
  ConsumerState<InventoryTransactionScreen> createState() =>
      _InventoryTransactionScreenState();
}

class _InventoryTransactionScreenState
    extends ConsumerState<InventoryTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedType;

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
        title: const Text('Inventory Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'New Transaction'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TransactionHistoryTab(selectedType: _selectedType),
          _NewTransactionTab(
            onComplete: () {
              _tabController.animateTo(0);
              ref.invalidate(transactionHistoryProvider);
              ref.invalidate(inventoryItemsProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _TransactionHistoryTab extends ConsumerWidget {
  final String? selectedType;

  const _TransactionHistoryTab({this.selectedType});

  Color _typeColor(TransactionType type) {
    switch (type) {
      case TransactionType.purchase:
        return AppColors.success;
      case TransactionType.issue:
        return AppColors.warning;
      case TransactionType.returnItem:
        return AppColors.info;
      case TransactionType.adjustment:
        return AppColors.adminColor;
      case TransactionType.disposal:
        return AppColors.error;
    }
  }

  IconData _typeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.purchase:
        return Icons.add_shopping_cart;
      case TransactionType.issue:
        return Icons.output;
      case TransactionType.returnItem:
        return Icons.assignment_return;
      case TransactionType.adjustment:
        return Icons.tune;
      case TransactionType.disposal:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionHistoryProvider(
      TransactionFilter(transactionType: selectedType),
    ));
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No transactions found',
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
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final t = transactions[index];
            final color = _typeColor(t.transactionType);
            final isInflow = t.transactionType == TransactionType.purchase ||
                t.transactionType == TransactionType.returnItem;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(_typeIcon(t.transactionType),
                      color: color, size: 20),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.item?.name ?? 'Item #${t.itemId.substring(0, 8)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${isInflow ? "+" : "-"}${t.quantity}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isInflow
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.transactionType.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(dateFormat.format(t.transactionDate)),
                    if (t.totalCost > 0) ...[
                      const Spacer(),
                      Text(
                        '\u20B9${t.totalCost.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
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
}

class _NewTransactionTab extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const _NewTransactionTab({required this.onComplete});

  @override
  ConsumerState<_NewTransactionTab> createState() =>
      _NewTransactionTabState();
}

class _NewTransactionTabState
    extends ConsumerState<_NewTransactionTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedItemId;
  TransactionType _transactionType = TransactionType.purchase;
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(
        inventoryItemsProvider(const InventoryFilter()));

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item selection
            itemsAsync.when(
              data: (items) => DropdownButtonFormField<String>(
                value: _selectedItemId,
                decoration: const InputDecoration(
                  labelText: 'Select Item *',
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      '${item.name} (Stock: ${item.currentStock})',
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedItemId = value),
                validator: (v) =>
                    v == null ? 'Select an item' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading items'),
            ),
            const SizedBox(height: 16),

            // Transaction type
            DropdownButtonFormField<TransactionType>(
              value: _transactionType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type *',
                prefixIcon: Icon(Icons.swap_horiz),
              ),
              items: TransactionType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _transactionType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity *',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty == true) return 'Required';
                if (int.tryParse(v!) == null || int.parse(v) <= 0) {
                  return 'Must be a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Unit cost
            TextFormField(
              controller: _unitCostController,
              decoration: const InputDecoration(
                labelText: 'Unit Cost',
                prefixText: '\u20B9 ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Reference number
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference Number',
                hintText: 'e.g., Invoice or PO number',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
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
                  : const Icon(Icons.check),
              label: const Text('Record Transaction'),
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
      final quantity = int.parse(_quantityController.text);
      final unitCost =
          double.tryParse(_unitCostController.text) ?? 0;

      await repo.recordTransaction({
        'item_id': _selectedItemId,
        'transaction_type': _transactionType.value,
        'quantity': quantity,
        'unit_cost': unitCost,
        'total_cost': unitCost * quantity,
        'reference_number': _referenceController.text.isEmpty
            ? null
            : _referenceController.text.trim(),
        'notes': _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        'transaction_date':
            DateTime.now().toIso8601String().split('T')[0],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction recorded')),
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
