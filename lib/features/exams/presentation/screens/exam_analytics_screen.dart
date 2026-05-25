import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/exams_provider.dart';

/// Computed analytics rows for a single exam — parsed from the raw
/// `marks + students + exam_subjects + subjects` join in
/// `ExamRepository.getMarksForExam`.
///
/// Pure value object — used by [ExamAnalyticsScreen] and trivially testable.
class _MarkRow {
  _MarkRow({
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    required this.subjectName,
    required this.marksObtained,
    required this.maxMarks,
    required this.passingMarks,
    required this.isAbsent,
  });

  final String studentId;
  final String studentName;
  final String? admissionNumber;
  final String subjectName;
  final double? marksObtained;
  final double maxMarks;
  final double passingMarks;
  final bool isAbsent;

  double? get percentage {
    final m = marksObtained;
    if (m == null || maxMarks <= 0) return null;
    return (m / maxMarks) * 100;
  }

  bool get isPassed {
    final m = marksObtained;
    if (m == null) return false;
    return m >= passingMarks;
  }

  static _MarkRow? fromRow(Map<String, dynamic> row) {
    final examSubject = row['exam_subjects'];
    if (examSubject == null) return null;

    final student = row['students'];
    final subjects = examSubject is Map ? examSubject['subjects'] : null;

    final firstName = student is Map ? (student['first_name'] ?? '') : '';
    final lastName = student is Map ? (student['last_name'] ?? '') : '';
    final fullName =
        ('$firstName $lastName').trim().isEmpty ? 'Unknown' : '$firstName $lastName'.trim();

    final maxMarks = examSubject is Map
        ? (examSubject['max_marks'] as num?)?.toDouble() ?? 0
        : 0.0;
    final passingMarks = examSubject is Map
        ? (examSubject['passing_marks'] as num?)?.toDouble() ?? 0
        : 0.0;

    return _MarkRow(
      studentId: (row['student_id'] ?? '').toString(),
      studentName: fullName,
      admissionNumber: student is Map ? student['admission_number'] as String? : null,
      subjectName: subjects is Map ? (subjects['name'] as String? ?? 'Subject') : 'Subject',
      marksObtained: (row['marks_obtained'] as num?)?.toDouble(),
      maxMarks: maxMarks,
      passingMarks: passingMarks,
      isAbsent: (row['is_absent'] as bool?) ?? false,
    );
  }
}

/// Aggregated per-student row: total marks across all subjects of an exam.
class _StudentTotal {
  _StudentTotal({
    required this.studentId,
    required this.studentName,
    required this.totalObtained,
    required this.totalMax,
    required this.subjectsTaken,
  });

  final String studentId;
  final String studentName;
  final double totalObtained;
  final double totalMax;
  final int subjectsTaken;

  double get percentage => totalMax <= 0 ? 0 : (totalObtained / totalMax) * 100;
}

/// Live analytics for a single exam.
///
/// Computes pass-rate, mean, top-3, subject-wise average and a
/// 10-point score distribution from the marks table — no `v_exam_analytics`
/// dependency because that view is for online_exams.
class ExamAnalyticsScreen extends ConsumerWidget {
  const ExamAnalyticsScreen({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examAsync = ref.watch(examByIdProvider(examId));
    final marksFuture = ref.watch(_examMarkRowsProvider(examId));

    return Scaffold(
      appBar: AppBar(
        title: examAsync.maybeWhen(
          data: (exam) => Text(exam?.name ?? 'Exam Analytics'),
          orElse: () => const Text('Exam Analytics'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_examMarkRowsProvider(examId)),
          ),
        ],
      ),
      body: marksFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                const Text(
                  WarmCopy.genericError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(_examMarkRowsProvider(examId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const _EmptyState();
          }
          return _AnalyticsBody(rows: rows);
        },
      ),
    );
  }
}

/// Internal provider — keeps the screen pure and lets the user refresh
/// without rebuilding the AppBar.
final _examMarkRowsProvider =
    FutureProvider.autoDispose.family<List<_MarkRow>, String>((ref, examId) async {
  final repo = ref.watch(examRepositoryProvider);
  final raw = await repo.getMarksForExam(examId);
  return raw
      .map(_MarkRow.fromRow)
      .whereType<_MarkRow>()
      .toList();
});

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No marks recorded yet.\nAnalytics will appear once teachers enter marks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.rows});
  final List<_MarkRow> rows;

  @override
  Widget build(BuildContext context) {
    final present = rows.where((r) => !r.isAbsent && r.marksObtained != null).toList();
    final passed = present.where((r) => r.isPassed).length;
    final passRate = present.isEmpty ? 0.0 : (passed / present.length) * 100;
    final meanPercent = present.isEmpty
        ? 0.0
        : present.map((r) => r.percentage ?? 0).reduce((a, b) => a + b) / present.length;
    final absent = rows.where((r) => r.isAbsent).length;

    // Subject-wise average
    final bySubject = <String, List<_MarkRow>>{};
    for (final r in present) {
      bySubject.putIfAbsent(r.subjectName, () => []).add(r);
    }
    final subjectAverages = bySubject.entries.map((e) {
      final pct = e.value.map((r) => r.percentage ?? 0).reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key, pct);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Per-student totals (top-3)
    final byStudent = <String, List<_MarkRow>>{};
    for (final r in present) {
      byStudent.putIfAbsent(r.studentId, () => []).add(r);
    }
    final totals = byStudent.entries.map((e) {
      final totalObtained = e.value.fold<double>(0, (s, r) => s + (r.marksObtained ?? 0));
      final totalMax = e.value.fold<double>(0, (s, r) => s + r.maxMarks);
      return _StudentTotal(
        studentId: e.key,
        studentName: e.value.first.studentName,
        totalObtained: totalObtained,
        totalMax: totalMax,
        subjectsTaken: e.value.length,
      );
    }).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final toppers = totals.take(3).toList();

    // Distribution buckets — 10 buckets of 10% each
    final buckets = List<int>.filled(10, 0);
    for (final r in present) {
      final pct = r.percentage ?? 0;
      final idx = (pct ~/ 10).clamp(0, 9);
      buckets[idx]++;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricRow(
          tiles: [
            _MetricTile(
              label: 'Pass rate',
              value: '${passRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle_outline,
              color: passRate >= 50 ? AppColors.success : AppColors.warning,
            ),
            _MetricTile(
              label: 'Average',
              value: '${meanPercent.toStringAsFixed(1)}%',
              icon: Icons.trending_up,
              color: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricRow(
          tiles: [
            _MetricTile(
              label: 'Students',
              value: '${byStudent.length}',
              icon: Icons.groups_outlined,
              color: AppColors.primary,
            ),
            _MetricTile(
              label: 'Absent',
              value: '$absent',
              icon: Icons.event_busy_outlined,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Top performers'),
        const SizedBox(height: 8),
        if (toppers.isEmpty)
          const _NoData('No graded students yet.')
        else
          ...toppers.asMap().entries.map((e) => _TopperRow(rank: e.key + 1, total: e.value)),
        const SizedBox(height: 24),
        const _SectionTitle('Subject average'),
        const SizedBox(height: 8),
        if (subjectAverages.isEmpty)
          const _NoData('No subject data yet.')
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: subjectAverages
                  .map((e) => _SubjectAvgRow(name: e.key, percent: e.value))
                  .toList(),
            ),
          ),
        const SizedBox(height: 24),
        const _SectionTitle('Score distribution'),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 220,
            child: _DistributionChart(buckets: buckets),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ===========================================================================
// Pieces
// ===========================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );
}

class _NoData extends StatelessWidget {
  const _NoData(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: TextStyle(color: Colors.grey[600])),
      );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.tiles});
  final List<_MetricTile> tiles;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: tiles[i]),
          ],
        ],
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopperRow extends StatelessWidget {
  const _TopperRow({required this.rank, required this.total});
  final int rank;
  final _StudentTotal total;

  @override
  Widget build(BuildContext context) {
    final medalColors = [
      const Color(0xFFFFD700), // gold
      const Color(0xFFC0C0C0), // silver
      const Color(0xFFCD7F32), // bronze
    ];
    final color = rank <= 3 ? medalColors[rank - 1] : Colors.grey;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              '$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(total.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${total.subjectsTaken} subject${total.subjectsTaken == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${total.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                '${total.totalObtained.toStringAsFixed(0)} / ${total.totalMax.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectAvgRow extends StatelessWidget {
  const _SubjectAvgRow({required this.name, required this.percent});
  final String name;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 50 ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionChart extends StatelessWidget {
  const _DistributionChart({required this.buckets});
  final List<int> buckets;

  @override
  Widget build(BuildContext context) {
    final maxCount = buckets.fold<int>(0, (m, v) => v > m ? v : m);
    final yMax = (maxCount + 2).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final lo = group.x * 10;
              final hi = lo + 10;
              return BarTooltipItem(
                '$lo-$hi%\n${rod.toY.toInt()} students',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${i * 10}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, _) {
                if (value % 1 != 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        barGroups: List.generate(buckets.length, (i) {
          final v = buckets[i].toDouble();
          final isPass = i >= 5; // 50%+ bucket counts as passing visually
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: v,
                color: isPass ? AppColors.success : AppColors.warning,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
