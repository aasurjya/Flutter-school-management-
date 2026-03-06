import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';

class VisitorStatsCard extends StatelessWidget {
  final VisitorStats stats;

  const VisitorStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Today's Overview",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total',
                  value: '${stats.todayTotal}',
                  color: AppColors.primary,
                  icon: Icons.groups,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Checked In',
                  value: '${stats.currentlyCheckedIn}',
                  color: AppColors.success,
                  icon: Icons.login,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Pre-Reg',
                  value: '${stats.preRegisteredToday}',
                  color: AppColors.info,
                  icon: Icons.event,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Checked Out',
                  value: '${stats.checkedOutToday}',
                  color: AppColors.accent,
                  icon: Icons.logout,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Denied',
                  value: '${stats.deniedToday}',
                  color: AppColors.error,
                  icon: Icons.block,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Blacklisted',
                  value: '${stats.blacklisted}',
                  color: Colors.grey,
                  icon: Icons.warning_amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
