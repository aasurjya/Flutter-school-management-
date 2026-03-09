import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card.dart';

class GradeTableWidget extends StatelessWidget {
  final List<SubjectGrade> grades;
  final double overallPercentage;
  final String overallGrade;
  final int rank;
  final int totalStudents;

  const GradeTableWidget({
    super.key,
    required this.grades,
    required this.overallPercentage,
    required this.overallGrade,
    required this.rank,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalObtained = 0;
    double totalMax = 0;
    for (final g in grades) {
      totalObtained += g.marksObtained ?? 0;
      totalMax += g.maxMarks ?? 0;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              border: TableBorder.all(
                color: theme.dividerColor,
              ),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.5),
                5: FlexColumnWidth(1.2),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  children: const [
                    _HeaderCell('#'),
                    _HeaderCell('Subject'),
                    _HeaderCell('Marks'),
                    _HeaderCell('Max'),
                    _HeaderCell('%'),
                    _HeaderCell('Grade'),
                  ],
                ),
                // Data rows
                ...grades.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final g = entry.value;
                  final pct = g.percentage ?? 0;

                  return TableRow(
                    decoration: BoxDecoration(
                      color: idx.isEven
                          ? Colors.transparent
                          : Colors.grey.withValues(alpha: 0.04),
                    ),
                    children: [
                      _DataCell('${idx + 1}'),
                      _DataCell(g.subjectName, align: TextAlign.left),
                      _DataCell(
                          g.marksObtained?.toStringAsFixed(0) ?? '-'),
                      _DataCell(
                          g.maxMarks?.toStringAsFixed(0) ?? '-'),
                      _DataCell('${pct.toStringAsFixed(1)}%'),
                      _GradeCell(g.grade ?? '-'),
                    ],
                  );
                }),
                // Total row
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                  children: [
                    const _DataCell('', bold: true),
                    const _DataCell('TOTAL', bold: true, align: TextAlign.left),
                    _DataCell(totalObtained.toStringAsFixed(0),
                        bold: true),
                    _DataCell(totalMax.toStringAsFixed(0), bold: true),
                    _DataCell(
                        '${overallPercentage.toStringAsFixed(1)}%',
                        bold: true),
                    _GradeCell(overallGrade, bold: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryBadge(
                label: 'Overall',
                value: '${overallPercentage.toStringAsFixed(1)}%',
                color: _percentColor(overallPercentage),
                icon: Icons.percent,
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor),
              _SummaryBadge(
                label: 'Grade',
                value: overallGrade,
                color: AppColors.gradeColor(overallGrade),
                icon: Icons.grade,
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor),
              _SummaryBadge(
                label: 'Rank',
                value: rank > 0 ? '#$rank' : 'N/A',
                color: Colors.amber,
                icon: Icons.emoji_events,
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor),
              _SummaryBadge(
                label: 'Result',
                value: overallPercentage >= 33 ? 'PASS' : 'FAIL',
                color: overallPercentage >= 33
                    ? AppColors.success
                    : AppColors.error,
                icon: overallPercentage >= 33
                    ? Icons.check_circle
                    : Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _percentColor(double pct) {
    if (pct >= 80) return AppColors.success;
    if (pct >= 60) return AppColors.info;
    if (pct >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool bold;
  final TextAlign align;

  const _DataCell(this.text,
      {this.bold = false, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _GradeCell extends StatelessWidget {
  final String grade;
  final bool bold;

  const _GradeCell(this.grade, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                AppColors.gradeColor(grade).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            grade,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: bold ? 13 : 12,
              color: AppColors.gradeColor(grade),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
