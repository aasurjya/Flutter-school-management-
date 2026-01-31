import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../exams/providers/exams_provider.dart';
import '../../../students/providers/students_provider.dart';

class StudentResultsScreen extends ConsumerStatefulWidget {
  final String? studentId;
  
  const StudentResultsScreen({super.key, this.studentId});

  @override
  ConsumerState<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends ConsumerState<StudentResultsScreen> {
  String? _selectedExamId;

  @override
  Widget build(BuildContext context) {
    final currentStudent = ref.watch(currentStudentProvider);
    final studentId = widget.studentId ?? currentStudent.valueOrNull?.id;

    if (studentId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final examsAsync = ref.watch(examsProvider(const ExamsFilter(publishedOnly: true)));
    final performanceAsync = ref.watch(studentPerformanceProvider(
      StudentPerformanceFilter(studentId: studentId, examId: _selectedExamId),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
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
                  Text('No exam results available yet'),
                ],
              ),
            );
          }

          _selectedExamId ??= exams.first.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExamSelector(exams),
                const SizedBox(height: 16),
                performanceAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (performance) {
                    if (performance.isEmpty) {
                      return const Center(child: Text('No results for this exam'));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverallStats(studentId, performance),
                        const SizedBox(height: 24),
                        _buildSubjectWiseResults(performance),
                        const SizedBox(height: 24),
                        _buildPerformanceChart(performance),
                        const SizedBox(height: 24),
                        _buildComparisonCard(studentId),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamSelector(List<dynamic> exams) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedExamId,
          isExpanded: true,
          hint: const Text('Select Exam'),
          items: exams.map((exam) {
            return DropdownMenuItem<String>(
              value: exam.id,
              child: Text(exam.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedExamId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildOverallStats(String studentId, List<dynamic> performance) {
    final overallRankAsync = ref.watch(studentOverallRankProvider(
      StudentExamFilter(studentId: studentId, examId: _selectedExamId!),
    ));

    return overallRankAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (overallRank) {
        if (overallRank == null) return const SizedBox.shrink();

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Marks',
                value: '${overallRank.totalObtained.toInt()}/${overallRank.totalMaxMarks.toInt()}',
                icon: Icons.assignment_turned_in,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Percentage',
                value: '${overallRank.overallPercentage.toStringAsFixed(1)}%',
                icon: Icons.percent,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Class Rank',
                value: '#${overallRank.classRank}',
                icon: Icons.emoji_events,
                color: AppColors.accent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectWiseResults(List<dynamic> performance) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject-wise Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...performance.map((p) {
            final color = p.isPassed ? AppColors.success : AppColors.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p.marksObtained.toInt()}/${p.maxMarks.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: p.percentage / 100,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${p.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(List<dynamic> performance) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Chart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${performance[groupIndex].subjectName}\n${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= performance.length) {
                          return const SizedBox.shrink();
                        }
                        final subject = performance[value.toInt()].subjectName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            subject.substring(0, subject.length > 4 ? 4 : subject.length),
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
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(performance.length, (index) {
                  final p = performance[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: p.percentage,
                        color: p.isPassed ? AppColors.success : AppColors.error,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  drawVerticalLine: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(String studentId) {
    if (_selectedExamId == null) return const SizedBox.shrink();

    final classStatsAsync = ref.watch(classExamStatsProvider(
      ClassStatsFilter(examId: _selectedExamId!),
    ));

    return classStatsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (classStats) {
        if (classStats.isEmpty) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comparison with Class',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...classStats.map((stat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          stat.subjectName,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: _ComparisonItem(
                          label: 'Avg',
                          value: '${stat.classAverage.toStringAsFixed(1)}%',
                          color: AppColors.info,
                        ),
                      ),
                      Expanded(
                        child: _ComparisonItem(
                          label: 'Top',
                          value: '${stat.highestPercentage.toStringAsFixed(1)}%',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ComparisonItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
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
    );
  }
}
