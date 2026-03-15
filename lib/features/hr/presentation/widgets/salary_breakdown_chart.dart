import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/hr_payroll.dart';

/// Pie chart showing salary component breakdown
class SalaryBreakdownChart extends StatelessWidget {
  final PayrollItem item;
  final double size;

  const SalaryBreakdownChart({
    super.key,
    required this.item,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = <_ChartSection>[];

    // Earnings
    for (final entry in item.earnings.entries) {
      final val = _toDouble(entry.value);
      if (val > 0) {
        sections.add(_ChartSection(
          label: _formatLabel(entry.key),
          value: val,
          color: _earningColor(sections.length),
        ));
      }
    }

    if (item.overtimeAmount > 0) {
      sections.add(_ChartSection(
        label: 'Overtime',
        value: item.overtimeAmount,
        color: AppColors.accent,
      ));
    }

    // Deductions
    for (final entry in item.deductions.entries) {
      final val = _toDouble(entry.value);
      if (val > 0) {
        sections.add(_ChartSection(
          label: _formatLabel(entry.key),
          value: val,
          color: _deductionColor(sections.length),
        ));
      }
    }

    if (item.taxAmount > 0) {
      sections.add(_ChartSection(
        label: 'Tax (TDS)',
        value: item.taxAmount,
        color: AppColors.error,
      ));
    }

    if (sections.isEmpty) {
      return SizedBox(
        height: size,
        child: const Center(child: Text('No salary data')),
      );
    }

    final total = sections.fold<double>(0, (sum, s) => sum + s.value);

    return Column(
      children: [
        SizedBox(
          height: size,
          child: PieChart(
            PieChartData(
              sections: sections.map((s) {
                return PieChartSectionData(
                  value: s.value,
                  title: '${(s.value / total * 100).toStringAsFixed(0)}%',
                  color: s.color,
                  radius: size / 3,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: size / 6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: sections.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.label}: \u20B9${s.value.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _earningColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      Color(0xFFF97316),
      Color(0xFF14B8A6),
    ];
    return colors[index % colors.length];
  }

  Color _deductionColor(int index) {
    const colors = [
      Color(0xFFF97316),
      Color(0xFFEF4444),
      Color(0xFFEC4899),
      Color(0xFF64748B),
    ];
    return colors[index % colors.length];
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static String _formatLabel(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

class _ChartSection {
  final String label;
  final double value;
  final Color color;

  const _ChartSection({
    required this.label,
    required this.value,
    required this.color,
  });
}
