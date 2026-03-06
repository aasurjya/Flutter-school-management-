import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';

class VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final VoidCallback? onTap;

  const VisitorCard({
    super.key,
    required this.visitor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: visitor.isBlacklisted
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: visitor.photoUrl != null
                ? NetworkImage(visitor.photoUrl!)
                : null,
            child: visitor.photoUrl == null
                ? Text(
                    visitor.initials,
                    style: TextStyle(
                      color: visitor.isBlacklisted
                          ? AppColors.error
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        visitor.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (visitor.isBlacklisted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Blacklisted',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (visitor.phone != null)
                  Text(
                    visitor.phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                if (visitor.company != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    visitor.company!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${visitor.visitCount} visits',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (visitor.idType != null) ...[
                const SizedBox(height: 4),
                Text(
                  visitor.idType!.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
