import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/student_insights.dart';
import '../../providers/insights_provider.dart';

class AttendanceChart extends ConsumerWidget {
  final String studentId;

  const AttendanceChart({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyDataAsync = ref.watch(
      monthlyAttendanceProvider(
        MonthlyAttendanceFilter(
          studentId: studentId,
          year: DateTime.now().year,
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Attendance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            monthlyDataAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No attendance data available'),
                    ),
                  );
                }
                return _MonthlyBarChart(data: data);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error: $e'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.green, label: 'Present'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.orange, label: 'Late'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.red, label: 'Absent'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyAttendanceSummary> data;

  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((month) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _MonthBar(summary: month),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final MonthlyAttendanceSummary summary;

  const _MonthBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = 150.0;

    if (summary.totalDays == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.monthName,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      );
    }

    final presentHeight =
        (summary.presentDays / summary.totalDays) * maxHeight;
    final lateHeight = (summary.lateDays / summary.totalDays) * maxHeight;
    final absentHeight = (summary.absentDays / summary.totalDays) * maxHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${summary.attendancePercentage.toStringAsFixed(0)}%',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Absent (top - red)
              if (absentHeight > 0)
                Container(
                  height: absentHeight.clamp(2, maxHeight),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              // Late (middle - orange)
              if (lateHeight > 0)
                Container(
                  height: lateHeight.clamp(2, maxHeight),
                  color: Colors.orange,
                ),
              // Present (bottom - green)
              if (presentHeight > 0)
                Container(
                  height: presentHeight.clamp(2, maxHeight),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.vertical(
                      bottom: const Radius.circular(4),
                      top: (absentHeight == 0 && lateHeight == 0)
                          ? const Radius.circular(4)
                          : Radius.zero,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          summary.monthName,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

/// Detailed attendance calendar view
class AttendanceCalendarView extends StatelessWidget {
  final String studentId;
  final List<Map<String, dynamic>> attendanceRecords;

  const AttendanceCalendarView({
    super.key,
    required this.studentId,
    required this.attendanceRecords,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Calendar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Simplified calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = attendanceRecords[index];
                final status = record['status'] as String;
                final date = DateTime.parse(record['date'] as String);

                return Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: status == 'present' ? Colors.white : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'holiday':
        return Colors.grey;
      default:
        return Colors.grey[300]!;
    }
  }
}
