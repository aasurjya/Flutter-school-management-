import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../exams/providers/exams_provider.dart';

class ChildResultsScreen extends ConsumerStatefulWidget {
  final String childId;
  final String? childName;

  const ChildResultsScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  @override
  ConsumerState<ChildResultsScreen> createState() => _ChildResultsScreenState();
}

class _ChildResultsScreenState extends ConsumerState<ChildResultsScreen> {
  String? _selectedExamId;

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsProvider(const ExamsFilter(publishedOnly: true)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.childName != null ? "${widget.childName}'s Results" : 'Exam Results'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (exams) {
          if (exams.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No exam results available'),
                ],
              ),
            );
          }

          final currentExamId = _selectedExamId ?? exams.first.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExamSelector(exams, currentExamId),
                const SizedBox(height: 16),
                _buildOverallPerformance(currentExamId),
                const SizedBox(height: 24),
                _buildSubjectWiseResults(currentExamId),
                const SizedBox(height: 24),
                _buildPerformanceComparison(currentExamId),
                const SizedBox(height: 24),
                _buildPerformanceTrend(exams),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamSelector(List<dynamic> exams, String currentExamId) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentExamId,
          isExpanded: true,
          items: exams.map((exam) {
            return DropdownMenuItem<String>(
              value: exam.id,
              child: Text(exam.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedExamId = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOverallPerformance(String examId) {
    final performanceAsync = ref.watch(studentPerformanceProvider(
      StudentPerformanceFilter(examId: examId, studentId: widget.childId),
    ));
    final rankAsync = ref.watch(studentRanksProvider(
      StudentRankFilter(examId: examId, studentId: widget.childId),
    ));

    return performanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (performance) {
        if (performance.isEmpty) {
          return const GlassCard(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No results available')),
          );
        }

        final totalObtained = performance.fold<double>(0, (sum, p) => sum + (p.marksObtained ?? 0));
        final totalMax = performance.fold<double>(0, (sum, p) => sum + (p.maxMarks ?? 0));
        final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
        final grade = _calculateGrade(percentage);

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Percentage Circle
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(_getGradeColor(grade)),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              grade,
                              style: TextStyle(
                                fontSize: 14,
                                color: _getGradeColor(grade),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow('Total Marks', '${totalObtained.toInt()} / ${totalMax.toInt()}'),
                        const SizedBox(height: 8),
                        _buildStatRow('Subjects', '${performance.length}'),
                        const SizedBox(height: 8),
                        rankAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (ranks) {
                            if (ranks.isEmpty) return const SizedBox.shrink();
                            final rank = ranks.first;
                            return _buildStatRow(
                              'Class Rank',
                              '#${rank.subjectRank} of ${rank.totalInSubject}',
                              highlight: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectWiseResults(String examId) {
    final performanceAsync = ref.watch(studentPerformanceProvider(
      StudentPerformanceFilter(examId: examId, studentId: widget.childId),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject-wise Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        performanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (performance) {
            if (performance.isEmpty) {
              return const Text('No data available');
            }

            return Column(
              children: performance.map((p) {
                final percentage = p.percentage ?? 0.0;
                final grade = _calculateGrade(percentage);
                final isPassed = percentage >= 33;

                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getGradeColor(grade).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getGradeColor(grade),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.subjectName ?? 'Subject',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation(
                                        isPassed ? AppColors.success : AppColors.error,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isPassed ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.marksObtained?.toInt() ?? 0}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '/ ${p.maxMarks?.toInt() ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceComparison(String examId) {
    final performanceAsync = ref.watch(studentPerformanceProvider(
      StudentPerformanceFilter(examId: examId, studentId: widget.childId),
    ));

    return performanceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (performance) {
        if (performance.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparison with Class',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= performance.length) {
                              return const SizedBox.shrink();
                            }
                            final subject = performance[value.toInt()].subjectName ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                subject.length > 4 ? subject.substring(0, 4) : subject,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                          },
                          reservedSize: 35,
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1);
                      },
                      drawVerticalLine: false,
                    ),
                    barGroups: List.generate(performance.length, (index) {
                      final p = performance[index];
                      // Using passing marks as a baseline comparison
                      final avgEstimate = p.passingMarks / p.maxMarks * 100 + 20; // Estimate class average
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: p.percentage,
                            color: AppColors.primary,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: avgEstimate.clamp(0, 100),
                            color: Colors.grey.withValues(alpha: 0.5),
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.primary, 'Your Child'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.grey.withValues(alpha: 0.5), 'Class Average'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPerformanceTrend(List<dynamic> exams) {
    if (exams.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1);
                  },
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= exams.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Exam ${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(exams.length, (index) {
                      // Mock data - in real app, fetch actual performance
                      return FlSpot(index.toDouble(), 65 + (index * 5).toDouble());
                    }),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    if (percentage >= 33) return 'E';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return AppColors.success;
      case 'B+':
      case 'B':
        return AppColors.info;
      case 'C':
        return AppColors.warning;
      case 'D':
      case 'E':
        return Colors.orange;
      default:
        return AppColors.error;
    }
  }
}
