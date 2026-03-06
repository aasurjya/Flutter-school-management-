import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final bool showImage;

  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
    this.showImage = true,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(asset.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showImage)
              SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (asset.imageUrl != null)
                      Image.network(
                        asset.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _AssetPlaceholder(assetCode: asset.assetCode),
                      )
                    else
                      _AssetPlaceholder(assetCode: asset.assetCode),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          asset.statusDisplay,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.assetCode,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _conditionColor(asset.condition),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        asset.conditionDisplay,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (asset.location != null)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textTertiaryLight,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  asset.location!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (asset.currentValue != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Value: ${_formatCurrency(asset.currentValue!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '\u20B9${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '\u20B9${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\u20B9${amount.toStringAsFixed(0)}';
  }
}

class AssetListTile extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AssetListTile({
    super.key,
    required this.asset,
    this.onTap,
    this.trailing,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(asset.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: statusColor.withValues(alpha: 0.1),
          ),
          child: asset.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    asset.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      color: statusColor,
                    ),
                  ),
                )
              : Icon(Icons.inventory_2_outlined, color: statusColor),
        ),
        title: Text(
          asset.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(asset.assetCode),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                asset.statusDisplay,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _AssetPlaceholder extends StatelessWidget {
  final String assetCode;

  const _AssetPlaceholder({required this.assetCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 4),
            Text(
              assetCode,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
