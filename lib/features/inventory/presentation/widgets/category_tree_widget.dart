import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';

class CategoryTreeWidget extends StatelessWidget {
  final List<AssetCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<AssetCategory>? onCategoryTap;
  final ValueChanged<AssetCategory>? onEdit;
  final ValueChanged<AssetCategory>? onDelete;
  final int depth;

  const CategoryTreeWidget({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.onCategoryTap,
    this.onEdit,
    this.onDelete,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.category_outlined,
                size: 48,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                'No categories found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: depth > 0
          ? const NeverScrollableScrollPhysics()
          : null,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _CategoryNode(
          category: categories[index],
          depth: depth,
          selectedCategoryId: selectedCategoryId,
          onCategoryTap: onCategoryTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _CategoryNode extends StatefulWidget {
  final AssetCategory category;
  final int depth;
  final String? selectedCategoryId;
  final ValueChanged<AssetCategory>? onCategoryTap;
  final ValueChanged<AssetCategory>? onEdit;
  final ValueChanged<AssetCategory>? onDelete;

  const _CategoryNode({
    required this.category,
    required this.depth,
    this.selectedCategoryId,
    this.onCategoryTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_CategoryNode> createState() => _CategoryNodeState();
}

class _CategoryNodeState extends State<_CategoryNode> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = widget.category.children.isNotEmpty;
    final isSelected = widget.selectedCategoryId == widget.category.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: widget.depth * 20.0,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : null,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: InkWell(
            onTap: () {
              if (hasChildren) {
                setState(() => _isExpanded = !_isExpanded);
              }
              widget.onCategoryTap?.call(widget.category);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (hasChildren)
                    Icon(
                      _isExpanded
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 20,
                      color: AppColors.textSecondaryLight,
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  Icon(
                    hasChildren
                        ? Icons.folder_outlined
                        : Icons.label_outline,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : null,
                          ),
                        ),
                        if (widget.category.depreciationRate > 0)
                          Text(
                            'Depreciation: ${widget.category.depreciationRate}%/yr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiaryLight,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.onEdit != null || widget.onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AppColors.textTertiaryLight,
                      ),
                      itemBuilder: (context) => [
                        if (widget.onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (widget.onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEdit?.call(widget.category);
                        } else if (value == 'delete') {
                          widget.onDelete?.call(widget.category);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasChildren && _isExpanded)
          CategoryTreeWidget(
            categories: widget.category.children,
            depth: widget.depth + 1,
            selectedCategoryId: widget.selectedCategoryId,
            onCategoryTap: widget.onCategoryTap,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          ),
      ],
    );
  }
}
