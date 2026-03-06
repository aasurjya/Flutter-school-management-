import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card_full.dart';

class SkillsRadarChart extends StatelessWidget {
  final List<ReportCardSkill> skills;

  const SkillsRadarChart({super.key, required this.skills});

  static const _skillOrder = [
    'leadership',
    'teamwork',
    'communication',
    'creativity',
    'critical_thinking',
    'time_management',
  ];

  static const _skillLabels = {
    'leadership': 'Leadership',
    'teamwork': 'Teamwork',
    'communication': 'Communication',
    'creativity': 'Creativity',
    'critical_thinking': 'Critical\nThinking',
    'time_management': 'Time\nManagement',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build skill map for lookup
    final skillMap = <String, int>{};
    for (final s in skills) {
      skillMap[s.skillCategory] = s.rating;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Radar Chart
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                dataSets: [
                  RadarDataSet(
                    dataEntries: _skillOrder.map((key) {
                      return RadarEntry(
                        value: (skillMap[key] ?? 3).toDouble(),
                      );
                    }).toList(),
                    fillColor: AppColors.primary.withValues(alpha: 0.2),
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                    entryRadius: 4,
                  ),
                  // Max reference ring
                  RadarDataSet(
                    dataEntries: _skillOrder
                        .map((_) => const RadarEntry(value: 5))
                        .toList(),
                    fillColor: Colors.transparent,
                    borderColor: Colors.grey.withValues(alpha: 0.2),
                    borderWidth: 1,
                    entryRadius: 0,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
                getTitle: (index, _) {
                  if (index >= _skillOrder.length) return RadarChartTitle(text: '');
                  final key = _skillOrder[index];
                  return RadarChartTitle(
                    text: _skillLabels[key] ?? key,
                  );
                },
                tickCount: 5,
                ticksTextStyle: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[400],
                ),
                tickBorderData: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                gridBorderData: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                radarBorderData: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Skill Details List
          ...skills.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      s.skillCategoryDisplay,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: List.generate(5, (i) {
                        final filled = i < s.rating;
                        return Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 20,
                          color: filled
                              ? _ratingColor(s.rating)
                              : Colors.grey[300],
                        );
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _ratingLabel(s.rating),
                      style: TextStyle(
                        fontSize: 11,
                        color: _ratingColor(s.rating),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (skills.any((s) => s.comments != null && s.comments!.isNotEmpty)) ...[
            const Divider(height: 24),
            ...skills.where((s) => s.comments != null && s.comments!.isNotEmpty).map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.skillCategoryDisplay}: ',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Text(
                        s.comments!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _ratingColor(int rating) {
    switch (rating) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return Colors.grey;
      case 4:
        return AppColors.info;
      case 5:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Needs Work';
      case 2:
        return 'Below Avg';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
