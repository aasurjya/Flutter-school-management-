import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

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
    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = currentUser?.isTeacher ?? false;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mark Attendance'),
            Tab(text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Mark Attendance Tab
          _buildMarkAttendanceTab(context, isTeacher || isAdmin),
          // Reports Tab
          _buildReportsTab(context),
        ],
      ),
    );
  }

  Widget _buildMarkAttendanceTab(BuildContext context, bool canMark) {
    if (!canMark) {
      return _buildStudentAttendanceView(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _selectDate,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // My Classes
          const Text(
            'Select Class to Mark Attendance',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Class Cards
          ..._mockClasses.map((cls) => _ClassAttendanceCard(
                className: cls['name'] as String,
                studentCount: cls['students'] as int,
                attendanceStatus: cls['status'] as String,
                percentage: cls['percentage'] as int,
                onTap: () => context.push(
                  '/attendance/mark/${cls['id']}?date=${_selectedDate.toIso8601String()}',
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary
          GlassCard(
            padding: const EdgeInsets.all(20),
            gradient: AppColors.primaryGradient,
            child: Column(
              children: [
                const Text(
                  'This Month\'s Attendance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '94.5%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AttendanceStat(label: 'Present', value: '21', color: Colors.white),
                    _AttendanceStat(label: 'Absent', value: '1', color: Colors.white),
                    _AttendanceStat(label: 'Late', value: '2', color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Weekly Calendar
          const Text(
            'This Week',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildWeeklyCalendar(),
          const SizedBox(height: 24),

          // Recent Attendance
          const Text(
            'Recent Attendance',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ..._mockAttendanceHistory.map((item) => _AttendanceHistoryItem(
                date: item['date']!,
                status: item['status']!,
                time: item['time']!,
              )),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final statuses = ['P', 'P', 'P', 'A', 'P', '-'];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(days.length, (index) {
          final status = statuses[index];
          final isPresent = status == 'P';
          final isAbsent = status == 'A';
          final isToday = index == 4;

          return Column(
            children: [
              Text(
                days[index],
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPresent
                      ? AppColors.success.withOpacity(0.1)
                      : isAbsent
                          ? AppColors.error.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: status == '-'
                      ? Text('-', style: TextStyle(color: Colors.grey[400]))
                      : Icon(
                          isPresent ? Icons.check : Icons.close,
                          color: isPresent ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Options
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: 'This Month',
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Today', 'This Week', 'This Month', 'This Term']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: 'All Classes',
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['All Classes', 'Class 10-A', 'Class 10-B', 'Class 9-A']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _ReportCard(
                  title: 'Average Attendance',
                  value: '92.5%',
                  icon: Icons.people,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportCard(
                  title: 'Absent Today',
                  value: '24',
                  icon: Icons.person_off,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Class-wise Report
          const Text(
            'Class-wise Attendance',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ..._mockClassReport.map((item) => _ClassReportItem(
                className: item['class'] as String,
                present: item['present'] as int,
                absent: item['absent'] as int,
                percentage: item['percentage'] as double,
              )),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ClassAttendanceCard extends StatelessWidget {
  final String className;
  final int studentCount;
  final String attendanceStatus;
  final int percentage;
  final VoidCallback onTap;

  const _ClassAttendanceCard({
    required this.className,
    required this.studentCount,
    required this.attendanceStatus,
    required this.percentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMarked = attendanceStatus == 'Marked';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  '$studentCount students',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMarked
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attendanceStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isMarked ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
              if (isMarked) ...[
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }
}

class _AttendanceHistoryItem extends StatelessWidget {
  final String date;
  final String status;
  final String time;

  const _AttendanceHistoryItem({
    required this.date,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = status == 'Present';
    final isLate = status == 'Late';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isPresent || isLate ? Icons.check_circle : Icons.cancel,
            color: isPresent
                ? AppColors.success
                : isLate
                    ? AppColors.warning
                    : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ClassReportItem extends StatelessWidget {
  final String className;
  final int present;
  final int absent;
  final double percentage;

  const _ClassReportItem({
    required this.className,
    required this.present,
    required this.absent,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(className, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              '$present P',
              style: const TextStyle(color: AppColors.success, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              '$absent A',
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: percentage >= 90
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: percentage >= 90 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock data
final _mockClasses = [
  {'id': '1', 'name': 'Class 10-A', 'students': 42, 'status': 'Marked', 'percentage': 95},
  {'id': '2', 'name': 'Class 9-B', 'students': 38, 'status': 'Pending', 'percentage': 0},
  {'id': '3', 'name': 'Class 12-A', 'students': 35, 'status': 'Marked', 'percentage': 88},
  {'id': '4', 'name': 'Class 11-B', 'students': 40, 'status': 'Pending', 'percentage': 0},
];

final _mockAttendanceHistory = [
  {'date': 'Today, 6 Dec', 'status': 'Present', 'time': '8:25 AM'},
  {'date': 'Yesterday, 5 Dec', 'status': 'Present', 'time': '8:30 AM'},
  {'date': 'Wednesday, 4 Dec', 'status': 'Late', 'time': '8:45 AM'},
  {'date': 'Tuesday, 3 Dec', 'status': 'Present', 'time': '8:20 AM'},
  {'date': 'Monday, 2 Dec', 'status': 'Absent', 'time': '-'},
];

final _mockClassReport = [
  {'class': 'Class 10-A', 'present': 40, 'absent': 2, 'percentage': 95.2},
  {'class': 'Class 10-B', 'present': 36, 'absent': 4, 'percentage': 90.0},
  {'class': 'Class 9-A', 'present': 38, 'absent': 3, 'percentage': 92.7},
  {'class': 'Class 9-B', 'present': 35, 'absent': 5, 'percentage': 87.5},
];
