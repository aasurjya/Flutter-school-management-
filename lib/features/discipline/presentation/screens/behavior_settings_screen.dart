import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/discipline_provider.dart';

class BehaviorSettingsScreen extends ConsumerStatefulWidget {
  const BehaviorSettingsScreen({super.key});

  @override
  ConsumerState<BehaviorSettingsScreen> createState() =>
      _BehaviorSettingsScreenState();
}

class _BehaviorSettingsScreenState
    extends ConsumerState<BehaviorSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Behavior Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Negative Categories'),
            Tab(text: 'Positive Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoryList(type: BehaviorCategoryType.negative),
          _CategoryList(type: BehaviorCategoryType.positive),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateCategoryDialog({BehaviorCategory? existing}) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final pointsController =
        TextEditingController(text: '${existing?.points ?? 5}');
    BehaviorCategoryType type =
        existing?.type ?? BehaviorCategoryType.negative;
    String selectedColor = existing?.color ?? '#EF4444';

    final colors = [
      '#EF4444', // red
      '#F97316', // orange
      '#F59E0B', // amber
      '#22C55E', // green
      '#3B82F6', // blue
      '#8B5CF6', // purple
      '#EC4899', // pink
      '#64748B', // slate
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing != null
                          ? 'Edit Category'
                          : 'Create Category',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Bullying, Helpfulness',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Type
                    const Text(
                      'Type',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(
                              () => type = BehaviorCategoryType.negative,
                            ),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    type == BehaviorCategoryType.negative
                                        ? AppColors.error
                                        : AppColors.error
                                            .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Negative',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        type == BehaviorCategoryType.negative
                                            ? Colors.white
                                            : AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(
                              () => type = BehaviorCategoryType.positive,
                            ),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    type == BehaviorCategoryType.positive
                                        ? AppColors.success
                                        : AppColors.success
                                            .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Positive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        type == BehaviorCategoryType.positive
                                            ? Colors.white
                                            : AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Points
                    TextField(
                      controller: pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Points',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Color
                    const Text(
                      'Color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        final color = _hexToColor(c);
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedColor = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          await _saveCategory(
                            existingId: existing?.id,
                            name: nameController.text.trim(),
                            description: descController.text.trim(),
                            type: type,
                            points:
                                int.tryParse(pointsController.text) ?? 5,
                            color: selectedColor,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          existing != null ? 'Save Changes' : 'Create',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveCategory({
    String? existingId,
    required String name,
    required String description,
    required BehaviorCategoryType type,
    required int points,
    required String color,
  }) async {
    try {
      final repo = ref.read(disciplineRepositoryProvider);

      if (existingId != null) {
        await repo.updateCategory(existingId, {
          'name': name,
          'description': description.isNotEmpty ? description : null,
          'type': type.value,
          'points': points,
          'color': color,
        });
      } else {
        final cat = BehaviorCategory(
          id: '',
          tenantId: repo.requireTenantId,
          name: name,
          type: type,
          points: points,
          color: color,
          description: description.isNotEmpty ? description : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createCategory(cat);
      }

      if (mounted) {
        context.showSuccessSnackBar(
          existingId != null ? 'Category updated' : 'Category created',
        );
        ref.invalidate(allCategoriesProvider);
        ref.invalidate(
          behaviorCategoriesProvider(BehaviorCategoryType.negative),
        );
        ref.invalidate(
          behaviorCategoriesProvider(BehaviorCategoryType.positive),
        );
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed: $e');
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

class _CategoryList extends ConsumerWidget {
  final BehaviorCategoryType type;

  const _CategoryList({required this.type});

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(allCategoriesProvider);

    return catsAsync.when(
      data: (allCats) {
        final cats = allCats.where((c) => c.type == type).toList();
        if (cats.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No ${type.value} categories',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cats.length,
          itemBuilder: (context, idx) {
            final cat = cats[idx];
            final color =
                cat.color != null ? _hexToColor(cat.color!) : Colors.grey;
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      type == BehaviorCategoryType.negative
                          ? Icons.warning_amber_rounded
                          : Icons.star_outline,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (cat.description != null)
                          Text(
                            cat.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cat.points} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        final state = context
                            .findAncestorStateOfType<
                                _BehaviorSettingsScreenState>();
                        state?._showCreateCategoryDialog(existing: cat);
                      } else if (action == 'toggle') {
                        final repo =
                            ref.read(disciplineRepositoryProvider);
                        await repo.updateCategory(
                          cat.id,
                          {'is_active': !cat.isActive},
                        );
                        ref.invalidate(allCategoriesProvider);
                      } else if (action == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Category?'),
                            content: Text(
                              'Are you sure you want to delete "${cat.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final repo =
                              ref.read(disciplineRepositoryProvider);
                          await repo.deleteCategory(cat.id);
                          ref.invalidate(allCategoriesProvider);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          cat.isActive ? 'Deactivate' : 'Activate',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
