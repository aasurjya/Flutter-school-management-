import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/category_tree_widget.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final flatCategoriesAsync = ref.watch(flatCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Categories'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create categories to organize your assets',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        _showCategoryDialog(context, ref, null, []),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }

          return CategoryTreeWidget(
            categories: categories,
            onEdit: (category) {
              flatCategoriesAsync.whenData((flat) {
                _showCategoryDialog(context, ref, category, flat);
              });
            },
            onDelete: (category) {
              _confirmDelete(context, ref, category);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          flatCategoriesAsync.whenData((flat) {
            _showCategoryDialog(context, ref, null, flat);
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    AssetCategory? existing,
    List<AssetCategory> allCategories,
  ) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final rateController = TextEditingController(
        text: existing?.depreciationRate.toString() ?? '0');
    String? parentId = existing?.parentCategoryId;
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              existing != null ? 'Edit Category' : 'New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: parentId,
                  decoration: const InputDecoration(
                    labelText: 'Parent Category',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None (Root)'),
                    ),
                    ...allCategories
                        .where((c) => c.id != existing?.id)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => parentId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Depreciation Rate (%/year)',
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) =>
                      setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                Navigator.pop(ctx);

                try {
                  final repo = ref.read(inventoryRepositoryProvider);
                  final data = {
                    'name': nameController.text.trim(),
                    'description': descController.text.isEmpty
                        ? null
                        : descController.text.trim(),
                    'parent_category_id': parentId,
                    'depreciation_rate':
                        double.tryParse(rateController.text) ?? 0,
                    'is_active': isActive,
                  };

                  if (existing != null) {
                    await repo.updateCategory(existing.id, data);
                  } else {
                    await repo.createCategory(data);
                  }

                  ref.invalidate(assetCategoriesProvider);
                  ref.invalidate(flatCategoriesProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existing != null
                            ? 'Category updated'
                            : 'Category created'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(existing != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AssetCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            'Are you sure you want to delete "${category.name}"? Assets in this category will be uncategorized.'),
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
                await repo.deleteCategory(category.id);
                ref.invalidate(assetCategoriesProvider);
                ref.invalidate(flatCategoriesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted')),
                  );
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
