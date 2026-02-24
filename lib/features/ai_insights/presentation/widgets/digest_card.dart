import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/parent_digest.dart';
import '../../../../shared/widgets/glass_card.dart';

class DigestCard extends StatelessWidget {
  final ParentDigest digest;
  final VoidCallback? onTap;

  const DigestCard({
    super.key,
    required this.digest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.summarize,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      digest.weekLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      digest.title,
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
              if (!digest.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              if (digest.hasUrgentItems)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.priority_high,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Attendance mini-bar
          if (digest.attendance.total > 0) ...[
            _buildAttendanceMiniBar(digest.attendance),
            const SizedBox(height: 10),
          ],

          // Summary preview
          if (digest.summary != null && digest.summary!.isNotEmpty)
            Text(
              digest.summary!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMiniBar(WeeklyAttendance att) {
    final total = att.total > 0 ? att.total : 1;
    return Row(
      children: [
        _MiniBarSegment(
          flex: att.present,
          total: total,
          color: AppColors.success,
          label: 'P: ${att.present}',
        ),
        const SizedBox(width: 4),
        _MiniBarSegment(
          flex: att.absent,
          total: total,
          color: AppColors.error,
          label: 'A: ${att.absent}',
        ),
        const SizedBox(width: 4),
        _MiniBarSegment(
          flex: att.late,
          total: total,
          color: AppColors.warning,
          label: 'L: ${att.late}',
        ),
      ],
    );
  }
}

class _MiniBarSegment extends StatelessWidget {
  final int flex;
  final int total;
  final Color color;
  final String label;

  const _MiniBarSegment({
    required this.flex,
    required this.total,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (flex == 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
