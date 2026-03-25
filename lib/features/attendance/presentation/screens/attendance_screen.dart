import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';

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
            tooltip: 'Calendar',
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

    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = currentUser?.isTeacher ?? false;

    // Teachers see their assigned sections; admins see all sections
    final sectionsAsync = isTeacher && currentUser != null
        ? ref.watch(classTeacherSectionsProvider(currentUser.id))
        : ref.watch(allSectionsProvider);

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

          // Class Cards from provider
          sectionsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load classes: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
            data: (sections) {
              if (sections.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No classes assigned'),
                  ),
                );
              }
              return Column(
                children: sections.map((section) {
                  final dailyAsync = ref.watch(
                    sectionDailyAttendanceProvider(
                      SectionDateFilter(
                        sectionId: section.id,
                        date: _selectedDate,
                      ),
                    ),
                  );

                  final String statusText;
                  final int percentage;
                  dailyAsync.whenOrNull(
                    data: (data) => data,
                  );

                  final dailyData = dailyAsync.valueOrNull;
                  if (dailyData != null) {
                    final total = (dailyData['total_students'] as num?)?.toInt() ?? 0;
                    final present = (dailyData['present_count'] as num?)?.toInt() ?? 0;
                    final lateCount = (dailyData['late_count'] as num?)?.toInt() ?? 0;
                    statusText = total > 0 ? 'Marked' : 'Pending';
                    percentage = total > 0
                        ? ((present + lateCount) * 100 ~/ total)
                        : 0;
                  } else {
                    statusText = dailyAsync.isLoading ? 'Loading...' : 'Pending';
                    percentage = 0;
                  }

                  final displayName = section.className != null
                      ? '${section.className} - ${section.name}'
                      : section.name;

                  return _ClassAttendanceCard(
                    className: displayName,
                    studentCount: section.studentCount ?? section.capacity,
                    attendanceStatus: statusText,
                    percentage: percentage,
                    onTap: () => context.push(
                      '/attendance/mark/${section.id}?date=${_selectedDate.toIso8601String()}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceView(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final studentId = currentUser?.id ?? '';

    final statsAsync = ref.watch(attendanceStatsProvider(studentId));

    // Fetch recent attendance (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final historyAsync = ref.watch(
      studentAttendanceProvider(
        StudentAttendanceFilter(
          studentId: studentId,
          startDate: thirtyDaysAgo,
          endDate: now,
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary
          statsAsync.when(
            loading: () => const GlassCard(
              padding: EdgeInsets.all(20),
              gradient: AppColors.primaryGradient,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            error: (error, _) => GlassCard(
              padding: const EdgeInsets.all(20),
              gradient: AppColors.primaryGradient,
              child: Center(
                child: Text(
                  'Failed to load stats: $error',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            data: (stats) {
              final presentDays = stats['present_days'] ?? 0;
              final absentDays = stats['absent_days'] ?? 0;
              final lateDays = stats['late_days'] ?? 0;
              final percentage = stats['attendance_percentage'] ?? 0;

              return GlassCard(
                padding: const EdgeInsets.all(20),
                gradient: AppColors.primaryGradient,
                child: Column(
                  children: [
                    const Text(
                      'This Month\'s Attendance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AttendanceStat(
                          label: 'Present',
                          value: '$presentDays',
                          color: Colors.white,
                        ),
                        _AttendanceStat(
                          label: 'Absent',
                          value: '$absentDays',
                          color: Colors.white,
                        ),
                        _AttendanceStat(
                          label: 'Late',
                          value: '$lateDays',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
          historyAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load history: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No attendance records found'),
                  ),
                );
              }
              return Column(
                children: records.map((record) {
                  return _AttendanceHistoryItem(
                    date: _formatDate(record.date),
                    status: record.status.displayName,
                    time: record.markedAt != null
                        ? _formatTime(record.markedAt!)
                        : '-',
                  );
                }).toList(),
              );
            },
          ),
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
                      ? AppColors.success.withValues(alpha: 0.1)
                      : isAbsent
                          ? AppColors.error.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
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
    final sectionsAsync = ref.watch(allSectionsProvider);
    final todayPercentageAsync = ref.watch(todayAttendancePercentageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Options
          sectionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (sections) {
              final classNames = ['All Classes'];
              for (final s in sections) {
                final name = s.className != null
                    ? '${s.className} - ${s.name}'
                    : s.name;
                if (!classNames.contains(name)) {
                  classNames.add(name);
                }
              }
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: 'This Month',
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['Today', 'This Week', 'This Month', 'This Term']
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: 'All Classes',
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: classNames
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {},
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Summary Cards
          todayPercentageAsync.when(
            loading: () => const Row(
              children: [
                Expanded(
                  child: _ReportCard(
                    title: 'Average Attendance',
                    value: '...',
                    icon: Icons.people,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _ReportCard(
                    title: 'Absent Today',
                    value: '...',
                    icon: Icons.person_off,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            error: (error, _) => Center(
              child: Text(
                'Failed to load summary: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (avgPercentage) {
              return Row(
                children: [
                  Expanded(
                    child: _ReportCard(
                      title: 'Average Attendance',
                      value: '${avgPercentage.toStringAsFixed(1)}%',
                      icon: Icons.people,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReportCard(
                      title: 'Avg Attendance %',
                      value: '${(100 - avgPercentage).toStringAsFixed(0)}%',
                      icon: Icons.person_off,
                      color: AppColors.error,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Class-wise Report
          const Text(
            'Class-wise Attendance',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          sectionsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Text(
                'Failed to load report: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (sections) {
              if (sections.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No sections found'),
                  ),
                );
              }
              return Column(
                children: sections.map((section) {
                  final dailyAsync = ref.watch(
                    sectionDailyAttendanceProvider(
                      SectionDateFilter(
                        sectionId: section.id,
                        date: _selectedDate,
                      ),
                    ),
                  );

                  final displayName = section.className != null
                      ? '${section.className} - ${section.name}'
                      : section.name;

                  return dailyAsync.when(
                    loading: () => _ClassReportItem(
                      className: displayName,
                      present: 0,
                      absent: 0,
                      percentage: 0,
                    ),
                    error: (_, __) => _ClassReportItem(
                      className: displayName,
                      present: 0,
                      absent: 0,
                      percentage: 0,
                    ),
                    data: (data) {
                      if (data == null) {
                        return _ClassReportItem(
                          className: displayName,
                          present: 0,
                          absent: 0,
                          percentage: 0,
                        );
                      }
                      final present =
                          (data['present_count'] as num?)?.toInt() ?? 0;
                      final absent =
                          (data['absent_count'] as num?)?.toInt() ?? 0;
                      final pct = (data['attendance_percentage'] as num?)
                              ?.toDouble() ??
                          0;
                      return _ClassReportItem(
                        className: displayName,
                        present: present,
                        absent: absent,
                        percentage: pct,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
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
              color: AppColors.primary.withValues(alpha: 0.1),
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
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
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
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
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
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
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

