import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class DonationProgressCard extends StatelessWidget {
  final String purpose;
  final double raised;
  final double? goal;
  final int donorCount;
  final VoidCallback? onTap;

  const DonationProgressCard({
    super.key,
    required this.purpose,
    required this.raised,
    this.goal,
    this.donorCount = 0,
    this.onTap,
  });

  IconData _purposeIcon(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'scholarship':
        return Icons.school;
      case 'infrastructure':
        return Icons.business;
      case 'sports':
        return Icons.sports_soccer;
      case 'library':
        return Icons.menu_book;
      default:
        return Icons.volunteer_activism;
    }
  }

  Color _purposeColor(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'scholarship':
        return AppColors.info;
      case 'infrastructure':
        return AppColors.accent;
      case 'sports':
        return AppColors.success;
      case 'library':
        return const Color(0xFFF97316);
      default:
        return AppColors.primary;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _purposeColor(purpose);
    final progress = goal != null && goal! > 0 ? (raised / goal!).clamp(0.0, 1.0) : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_purposeIcon(purpose), color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  purpose[0].toUpperCase() + purpose.substring(1),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '\u20B9${_formatAmount(raised)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (goal != null) ...[
                Text(
                  ' / \u20B9${_formatAmount(goal!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '$donorCount donors',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          if (goal != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% of goal reached',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
