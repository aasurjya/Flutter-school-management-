import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';

class StockLevelIndicator extends StatelessWidget {
  final InventoryItem item;
  final bool showLabels;
  final double height;

  const StockLevelIndicator({
    super.key,
    required this.item,
    this.showLabels = true,
    this.height = 8,
  });

  Color _stockColor() {
    if (item.isOutOfStock) return AppColors.error;
    if (item.isLowStock) return AppColors.warning;
    if (item.isOverStock) return AppColors.info;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _stockColor();
    final percentage = item.stockPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.currentStock} ${item.unit.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  'Max: ${item.maximumStock}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
            // Reorder point marker
            if (item.maximumStock > 0) ...[
              Positioned(
                left: (item.reorderPoint / item.maximumStock).clamp(0.0, 1.0) *
                    (MediaQuery.of(context).size.width - 64),
                child: Container(
                  width: 2,
                  height: height,
                  color: AppColors.warning.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        if (showLabels && item.isLowStock)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  item.isOutOfStock
                      ? 'Out of stock!'
                      : 'Low stock - reorder at ${item.reorderPoint}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: item.isOutOfStock
                        ? AppColors.error
                        : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class StockLevelChip extends StatelessWidget {
  final InventoryItem item;

  const StockLevelChip({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    String label;

    if (item.isOutOfStock) {
      color = AppColors.error;
      label = 'Out of Stock';
    } else if (item.isLowStock) {
      color = AppColors.warning;
      label = 'Low Stock';
    } else if (item.isOverStock) {
      color = AppColors.info;
      label = 'Over Stock';
    } else {
      color = AppColors.success;
      label = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
