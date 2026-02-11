import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../students/providers/students_provider.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const StudentAttendanceScreen({super.key, this.studentId});

  @override
  ConsumerState<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends ConsumerState<StudentAttendanceScreen> {
  DateTime _selectedMonth = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    final currentStudentAsync = ref.watch(currentStudentProvider);

    return currentStudentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (student) {
        if (student == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Attendance'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Student not found')),
          );
        }

        final studentId = widget.studentId ?? student.id;
        final statsAsync = ref.watch(attendanceStatsProvider(studentId));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Attendance'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                statsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading stats: $e'),
                  data: (stats) => _buildSummaryCards(stats),
                ),
            const SizedBox(height: 24),
            
            // Month Selector
            _buildMonthSelector(),
            const SizedBox(height: 16),
            
            // Calendar View
            _buildCalendarView(),
            const SizedBox(height: 24),
            
            // Recent Attendance List
                const Text(
                  'Recent Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentAttendance(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic>? summary) {
    final present = summary?['present_days'] ?? 0;
    final absent = summary?['absent_days'] ?? 0;
    final late = summary?['late_days'] ?? 0;
    final total = summary?['total_days'] ?? 0;
    final percentage = summary?['attendance_percentage'] ?? 0.0;

    return Column(
      children: [
        // Main percentage card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
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
                      valueColor: AlwaysStoppedAnimation(
                        percentage >= 75 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
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
                    _buildStatRow(Icons.check_circle, 'Present', '$present days', AppColors.success),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.cancel, 'Absent', '$absent days', AppColors.error),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.access_time, 'Late', '$late days', AppColors.warning),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.calendar_today, 'Total', '$total days', AppColors.info),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Status indicator
        if (percentage < 75)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your attendance is below 75%. Please improve to avoid academic penalties.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            });
          },
          icon: const Icon(Icons.chevron_left),
        ),
        GestureDetector(
          onTap: _showMonthPicker,
          child: Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _selectedMonth.month < DateTime.now().month || 
                    _selectedMonth.year < DateTime.now().year
              ? () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _showMonthPicker() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = DateTime(selected.year, selected.month);
      });
    }
  }

  Widget _buildCalendarView() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Mock attendance data - in real app, fetch from provider
    final attendanceData = <int, String>{};
    // Populate with sample data
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, i);
      if (date.weekday != DateTime.sunday && date.isBefore(DateTime.now())) {
        // Random attendance for demo
        if (i % 7 == 0) {
          attendanceData[i] = 'absent';
        } else if (i % 11 == 0) {
          attendanceData[i] = 'late';
        } else {
          attendanceData[i] = 'present';
        }
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: ((firstWeekday % 7) + daysInMonth),
            itemBuilder: (context, index) {
              if (index < (firstWeekday % 7)) {
                return const SizedBox();
              }
              
              final day = index - (firstWeekday % 7) + 1;
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final status = attendanceData[day];
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final isFuture = date.isAfter(DateTime.now());
              final isSunday = date.weekday == DateTime.sunday;

              Color? bgColor;
              Color textColor = Colors.black;
              
              if (isFuture || isSunday) {
                textColor = Colors.grey[400]!;
              } else if (status == 'present') {
                bgColor = AppColors.success.withValues(alpha: 0.2);
                textColor = AppColors.success;
              } else if (status == 'absent') {
                bgColor = AppColors.error.withValues(alpha: 0.2);
                textColor = AppColors.error;
              } else if (status == 'late') {
                bgColor = AppColors.warning.withValues(alpha: 0.2);
                textColor = AppColors.warning;
              }

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(AppColors.success, 'Present'),
              _buildLegendItem(AppColors.error, 'Absent'),
              _buildLegendItem(AppColors.warning, 'Late'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRecentAttendance() {
    // Mock recent attendance data
    final recentDays = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      if (date.weekday == DateTime.sunday) return null;
      return {
        'date': date,
        'status': index == 3 ? 'absent' : (index == 5 ? 'late' : 'present'),
        'markedAt': '08:${30 + index}',
      };
    }).whereType<Map<String, dynamic>>().toList();

    return Column(
      children: recentDays.map((day) {
        final date = day['date'] as DateTime;
        final status = day['status'] as String;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(date),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Marked at ${day['markedAt']} AM',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }
}
