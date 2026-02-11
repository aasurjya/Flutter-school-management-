import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class TeacherTimetableScreen extends ConsumerStatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  ConsumerState<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends ConsumerState<TeacherTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    int initialIndex = DateTime.now().weekday - 1;
    if (initialIndex > 5) initialIndex = 0;
    _tabController = TabController(length: 6, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock timetable data for teacher
  List<Map<String, dynamic>> _getSchedule(String day) {
    if (day == 'Saturday') {
      return [
        {'period': 1, 'startTime': '08:00', 'endTime': '08:45', 'class': '10-A', 'subject': 'Mathematics', 'room': '101'},
        {'period': 2, 'startTime': '08:45', 'endTime': '09:30', 'class': '10-B', 'subject': 'Mathematics', 'room': '102'},
      ];
    }
    return [
      {'period': 1, 'startTime': '08:00', 'endTime': '08:45', 'class': '10-A', 'subject': 'Mathematics', 'room': '101'},
      {'period': 2, 'startTime': '08:45', 'endTime': '09:30', 'class': '10-B', 'subject': 'Mathematics', 'room': '102'},
      {'period': 3, 'startTime': '09:30', 'endTime': '10:15', 'class': null, 'subject': 'Free Period', 'room': null},
      {'period': 4, 'startTime': '10:15', 'endTime': '10:30', 'class': null, 'subject': 'Break', 'room': null, 'isBreak': true},
      {'period': 5, 'startTime': '10:30', 'endTime': '11:15', 'class': '11-A', 'subject': 'Mathematics', 'room': '201'},
      {'period': 6, 'startTime': '11:15', 'endTime': '12:00', 'class': '9-A', 'subject': 'Physics', 'room': '103'},
      {'period': 7, 'startTime': '12:00', 'endTime': '12:45', 'class': '9-B', 'subject': 'Physics', 'room': 'Lab 1'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildTodaySummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(6, (index) {
                final schedule = _getSchedule(_fullDays[index]);
                return _buildDaySchedule(schedule, _fullDays[index]);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    final today = DateFormat('EEEE').format(DateTime.now());
    final todaySchedule = _getSchedule(today);
    final classCount = todaySchedule.where((s) => s['class'] != null && s['isBreak'] != true).length;
    final freeCount = todaySchedule.where((s) => s['class'] == null && s['isBreak'] != true).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(DateFormat('EEEE, MMMM d').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('$classCount classes', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('$freeCount free', style: const TextStyle(fontSize: 12, color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(List<Map<String, dynamic>> schedule, String day) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        final entry = schedule[index];
        final isCurrentPeriod = _isCurrentPeriod(entry, day);
        return _PeriodCard(entry: entry, isCurrentPeriod: isCurrentPeriod, index: index);
      },
    );
  }

  bool _isCurrentPeriod(Map<String, dynamic> entry, String day) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    if (currentDay != day) return false;

    try {
      final startParts = (entry['startTime'] as String).split(':');
      final endParts = (entry['endTime'] as String).split(':');
      final startTime = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      final endTime = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
      return now.isAfter(startTime) && now.isBefore(endTime);
    } catch (_) {
      return false;
    }
  }
}

class _PeriodCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isCurrentPeriod;
  final int index;

  const _PeriodCard({required this.entry, required this.isCurrentPeriod, required this.index});

  @override
  Widget build(BuildContext context) {
    final isBreak = entry['isBreak'] == true;
    final isFree = entry['class'] == null && !isBreak;
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.info, AppColors.success, Colors.purple, Colors.teal];
    final color = isBreak ? Colors.orange : (isFree ? Colors.grey : colors[index % colors.length]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isCurrentPeriod ? Border.all(color: AppColors.success, width: 2) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        Text(_formatTime(entry['startTime']), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                        Container(width: 1, height: 16, color: color.withValues(alpha: 0.3)),
                        Text(_formatTime(entry['endTime']), style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('Period ${entry['period']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
                              ),
                              if (isBreak) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('BREAK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ),
                              ],
                              if (isFree) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('FREE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isBreak ? 'Break Time' : (isFree ? 'Free Period' : entry['subject']),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (entry['class'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.class_, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('Class ${entry['class']}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                if (entry['room'] != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.room, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('Room ${entry['room']}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (entry['class'] != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          // Navigate to class details
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isCurrentPeriod)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }
}
