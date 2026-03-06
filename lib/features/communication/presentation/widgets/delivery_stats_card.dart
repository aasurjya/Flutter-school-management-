import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';

class DeliveryStatsCard extends StatelessWidget {
  final CampaignStats stats;
  final bool compact;

  const DeliveryStatsCard({
    super.key,
    required this.stats,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompact(theme);
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Report',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          _buildProgressBar(),
          const SizedBox(height: 16),
          // Stats grid
          Row(
            children: [
              _buildStatItem(
                label: 'Total',
                value: '${stats.total}',
                color: AppColors.textSecondaryLight,
              ),
              _buildStatItem(
                label: 'Sent',
                value: '${stats.sent}',
                color: AppColors.info,
              ),
              _buildStatItem(
                label: 'Delivered',
                value: '${stats.delivered}',
                color: AppColors.success,
              ),
              _buildStatItem(
                label: 'Read',
                value: '${stats.read}',
                color: AppColors.primary,
              ),
              _buildStatItem(
                label: 'Failed',
                value: '${stats.failed}',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rate indicators
          Row(
            children: [
              Expanded(
                child: _buildRateChip(
                  'Delivery Rate',
                  stats.deliveryRate,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRateChip(
                  'Read Rate',
                  stats.readRate,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(ThemeData theme) {
    return Row(
      children: [
        _buildMiniStat('${stats.sent}', 'Sent', AppColors.info),
        const SizedBox(width: 12),
        _buildMiniStat('${stats.delivered}', 'Delivered', AppColors.success),
        const SizedBox(width: 12),
        _buildMiniStat('${stats.failed}', 'Failed', AppColors.error),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (stats.total == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: const LinearProgressIndicator(
          value: 0,
          minHeight: 8,
          backgroundColor: Color(0xFFE2E8F0),
        ),
      );
    }

    final readFraction = stats.read / stats.total;
    final deliveredFraction = (stats.delivered - stats.read) / stats.total;
    final sentFraction =
        (stats.sent - stats.delivered) / stats.total;
    final failedFraction = stats.failed / stats.total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (readFraction > 0)
              Expanded(
                flex: (readFraction * 100).round().clamp(1, 100),
                child: Container(color: AppColors.primary),
              ),
            if (deliveredFraction > 0)
              Expanded(
                flex: (deliveredFraction * 100).round().clamp(1, 100),
                child: Container(color: AppColors.success),
              ),
            if (sentFraction > 0)
              Expanded(
                flex: (sentFraction * 100).round().clamp(1, 100),
                child: Container(color: AppColors.info),
              ),
            if (failedFraction > 0)
              Expanded(
                flex: (failedFraction * 100).round().clamp(1, 100),
                child: Container(color: AppColors.error),
              ),
            if (stats.pending > 0)
              Expanded(
                flex: ((stats.pending / stats.total) * 100).round().clamp(1, 100),
                child: Container(color: const Color(0xFFE2E8F0)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRateChip(String label, double rate, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
