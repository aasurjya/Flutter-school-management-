import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admission.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Funnel visualization of the admissions pipeline
class AdmissionPipelineChart extends StatelessWidget {
  final AdmissionStats stats;

  const AdmissionPipelineChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stages = [
      _PipelineStage(
        'Inquiries',
        stats.totalInquiries,
        const Color(0xFF6366F1),
        Icons.contact_mail,
      ),
      _PipelineStage(
        'Applications',
        stats.totalApplications,
        const Color(0xFF3B82F6),
        Icons.description,
      ),
      _PipelineStage(
        'Under Review',
        stats.underReview + stats.submitted,
        const Color(0xFFF59E0B),
        Icons.rate_review,
      ),
      _PipelineStage(
        'Interview',
        stats.interviewScheduled,
        const Color(0xFF8B5CF6),
        Icons.people,
      ),
      _PipelineStage(
        'Accepted',
        stats.accepted,
        const Color(0xFF22C55E),
        Icons.check_circle,
      ),
      _PipelineStage(
        'Enrolled',
        stats.enrolled,
        const Color(0xFF059669),
        Icons.school,
      ),
    ];

    final maxCount =
        stages.fold<int>(0, (prev, s) => s.count > prev ? s.count : prev);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Admission Pipeline',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...stages.map((stage) => _buildStageBar(
                context,
                stage,
                maxCount,
                isDark,
              )),
          const SizedBox(height: 16),
          // Conversion rates
          Row(
            children: [
              _buildRateChip(
                'Conversion',
                '${(stats.conversionRate * 100).toStringAsFixed(0)}%',
                AppColors.info,
              ),
              const SizedBox(width: 12),
              _buildRateChip(
                'Acceptance',
                '${(stats.acceptanceRate * 100).toStringAsFixed(0)}%',
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageBar(
    BuildContext context,
    _PipelineStage stage,
    int maxCount,
    bool isDark,
  ) {
    final fraction = maxCount > 0 ? stage.count / maxCount : 0.0;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(stage.icon, size: 16, color: stage.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stage.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: stage.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.05, 1.0),
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          stage.color.withValues(alpha: 0.7),
                          stage.color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${stage.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineStage {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _PipelineStage(this.label, this.count, this.color, this.icon);
}
