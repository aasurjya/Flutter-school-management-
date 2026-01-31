import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../exams/providers/exams_provider.dart';
import '../../../attendance/providers/attendance_provider.dart';

class ClassAnalyticsScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String? sectionName;

  const ClassAnalyticsScreen({
    super.key,
    required this.sectionId,
    this.sectionName,
  });

  @override
  ConsumerState<ClassAnalyticsScreen> createState() => _ClassAnalyticsScreenState();
}

class _ClassAnalyticsScreenState extends ConsumerState<ClassAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedExamId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionName ?? 'Class Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Exam Performance'),
            Tab(text: 'Attendance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExamPerformanceTab(
            sectionId: widget.sectionId,
            selectedExamId: _selectedExamId,
            onExamSelected: (examId) {
              setState(() => _selectedExamId = examId);
            },
          ),
          _AttendanceTab(sectionId: widget.sectionId),
        ],
      ),
    );
  }
}

class _ExamPerformanceTab extends ConsumerWidget {
  final String sectionId;
  final String? selectedExamId;
  final void Function(String) onExamSelected;

  const _ExamPerformanceTab({
    required this.sectionId,
    required this.selectedExamId,
    required this.onExamSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider(const ExamsFilter(publishedOnly: true)));

    return examsAsync.when(
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
                Text('No published exams yet'),
              ],
            ),
          );
        }

        final currentExamId = selectedExamId ?? exams.first.id;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExamSelector(context, exams, currentExamId),
              const SizedBox(height: 16),
              _buildClassStats(ref, currentExamId),
              const SizedBox(height: 24),
              _buildSubjectWiseStats(ref, currentExamId),
              const SizedBox(height: 24),
              _buildTopPerformers(ref, currentExamId),
              const SizedBox(height: 24),
              _buildWeakStudents(ref, currentExamId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamSelector(BuildContext context, List<dynamic> exams, String currentExamId) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentExamId,
          isExpanded: true,
          hint: const Text('Select Exam'),
          items: exams.map((exam) {
            return DropdownMenuItem<String>(
              value: exam.id,
              child: Text(exam.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onExamSelected(value);
          },
        ),
      ),
    );
  }

  Widget _buildClassStats(WidgetRef ref, String examId) {
    final statsAsync = ref.watch(classExamStatsProvider(
      ClassStatsFilter(examId: examId, sectionId: sectionId),
    ));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (stats) {
        if (stats.isEmpty) {
          return const GlassCard(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No data available')),
          );
        }

        // Aggregate stats across all subjects
        final totalStudents = stats.fold<int>(0, (sum, s) => sum + s.totalStudents);
        final avgPercentage = stats.fold<double>(0, (sum, s) => sum + s.classAverage) / stats.length;
        final passedTotal = stats.fold<int>(0, (sum, s) => sum + s.passedCount);
        final failedTotal = stats.fold<int>(0, (sum, s) => sum + s.failedCount);

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Students',
                value: '${stats.first.studentsAppeared}',
                icon: Icons.people,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Class Avg',
                value: '${avgPercentage.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Pass Rate',
                value: '${((passedTotal / (passedTotal + failedTotal)) * 100).toStringAsFixed(0)}%',
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectWiseStats(WidgetRef ref, String examId) {
    final statsAsync = ref.watch(classExamStatsProvider(
      ClassStatsFilter(examId: examId, sectionId: sectionId),
    ));

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.isEmpty) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subject-wise Performance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
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
                            if (value.toInt() >= stats.length) return const SizedBox.shrink();
                            final subject = stats[value.toInt()].subjectName;
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
                        return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                      },
                      drawVerticalLine: false,
                    ),
                    barGroups: List.generate(stats.length, (index) {
                      final s = stats[index];
                      final passRate = s.passPercentage;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: s.classAverage,
                            color: passRate >= 60 ? AppColors.success : AppColors.warning,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...stats.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(s.subjectName, style: const TextStyle(fontSize: 13))),
                    Expanded(
                      child: Text(
                        'Avg: ${s.classAverage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Top: ${s.highestPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, color: AppColors.success),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.passPercentage >= 60
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${s.passPercentage.toStringAsFixed(0)}% pass',
                        style: TextStyle(
                          fontSize: 11,
                          color: s.passPercentage >= 60 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopPerformers(WidgetRef ref, String examId) {
    final toppersAsync = ref.watch(examToppersProvider(
      ExamToppersFilter(examId: examId, sectionId: sectionId, limit: 5),
    ));

    return toppersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (toppers) {
        if (toppers.isEmpty) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Top Performers',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...toppers.asMap().entries.map((entry) {
                final index = entry.key;
                final student = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: index == 0
                        ? AppColors.accent
                        : index == 1
                            ? Colors.grey[400]
                            : Colors.brown[300],
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student.studentName),
                  subtitle: Text('Roll: ${student.admissionNumber}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${student.overallPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '${student.totalObtained.toInt()}/${student.totalMaxMarks.toInt()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildWeakStudents(WidgetRef ref, String examId) {
    final toppersAsync = ref.watch(examToppersProvider(
      ExamToppersFilter(examId: examId, sectionId: sectionId, limit: 50),
    ));

    return toppersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (students) {
        // Filter students with percentage below 40%
        final weakStudents = students.where((s) => s.overallPercentage < 40).toList();
        
        if (weakStudents.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                const Text('All students passed!'),
              ],
            ),
          );
        }

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Needs Attention',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${weakStudents.length} students',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...weakStudents.take(5).map((student) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  child: Text(
                    student.studentName[0],
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                title: Text(student.studentName),
                subtitle: Text('Roll: ${student.admissionNumber}'),
                trailing: Text(
                  '${student.overallPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  final String sectionId;

  const _AttendanceTab({required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStats = ref.watch(sectionDailyAttendanceProvider(
      SectionDateFilter(sectionId: sectionId, date: DateTime.now()),
    ));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Attendance",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          todayStats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (stats) {
              if (stats == null) {
                return const GlassCard(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No attendance marked today')),
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Present',
                          value: '${stats['present_count'] ?? 0}',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Absent',
                          value: '${stats['absent_count'] ?? 0}',
                          icon: Icons.cancel,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Late',
                          value: '${stats['late_count'] ?? 0}',
                          icon: Icons.access_time,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: (stats['attendance_percentage'] ?? 0) / 100,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(
                                  (stats['attendance_percentage'] ?? 0) >= 75
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                              Text(
                                '${(stats['attendance_percentage'] ?? 0).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Students: ${stats['total_students'] ?? 0}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Attendance Rate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
