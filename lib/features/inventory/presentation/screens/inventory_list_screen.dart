import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/stock_level_indicator.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState
    extends ConsumerState<InventoryListScreen> {
  String? _selectedCategory;
  bool _lowStockOnly = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  InventoryFilter get _currentFilter => InventoryFilter(
        categoryId: _selectedCategory,
        lowStockOnly: _lowStockOnly ? true : null,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsProvider(_currentFilter));
    final categoriesAsync = ref.watch(flatCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Transaction History',
            onPressed: () => context.push('/inventory/transactions'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.inputFillLight,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: _lowStockOnly,
                  onSelected: (val) =>
                      setState(() => _lowStockOnly = val),
                  avatar: _lowStockOnly
                      ? null
                      : const Icon(Icons.warning_amber, size: 16),
                  selectedColor: AppColors.warning.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 8),
                categoriesAsync.when(
                  data: (categories) => Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (_) => setState(
                                  () => _selectedCategory = null),
                            ),
                          ),
                          ...categories.map(
                            (c) => Padding(
                              padding:
                                  const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(c.name),
                                selected:
                                    _selectedCategory == c.id,
                                onSelected: (_) => setState(
                                    () => _selectedCategory = c.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Item list
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_outlined,
                            size: 64,
                            color: AppColors.textTertiaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _InventoryItemCard(item: items[index]);
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showCreateItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '10');
    final maxCtrl = TextEditingController(text: '100');
    final costCtrl = TextEditingController();
    InventoryUnit unit = InventoryUnit.pieces;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New Inventory Item',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item Code *',
                    hintText: 'e.g., INV-PAPER-A4',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., A4 Paper Ream',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Current Stock',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<InventoryUnit>(
                        value: unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                        ),
                        items: InventoryUnit.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => unit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Max Stock',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unit Cost',
                    prefixText: '\u20B9 ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final repo =
                          ref.read(inventoryRepositoryProvider);
                      await repo.createInventoryItem({
                        'item_code': codeCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'unit': unit.value,
                        'current_stock':
                            int.tryParse(stockCtrl.text) ?? 0,
                        'minimum_stock':
                            int.tryParse(minCtrl.text) ?? 10,
                        'maximum_stock':
                            int.tryParse(maxCtrl.text) ?? 100,
                        'reorder_point':
                            int.tryParse(minCtrl.text) ?? 10,
                        'unit_cost':
                            double.tryParse(costCtrl.text) ?? 0,
                      });
                      ref.invalidate(inventoryItemsProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Item created')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Create Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.itemCode} | ${item.unit.label}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                StockLevelChip(item: item),
              ],
            ),
            const SizedBox(height: 12),
            StockLevelIndicator(item: item),
            if (item.unitCost > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit Cost: \u20B9${item.unitCost.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    'Stock Value: \u20B9${item.stockValue.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            if (item.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textTertiaryLight),
                  const SizedBox(width: 4),
                  Text(
                    item.location!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
