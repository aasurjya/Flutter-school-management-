import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/timetable.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../students/providers/students_provider.dart';
import '../../../timetable/providers/timetable_provider.dart';

class StudentTimetableScreen extends ConsumerStatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  ConsumerState<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends ConsumerState<StudentTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    // Set initial tab to current day (0 = Monday)
    int initialIndex = DateTime.now().weekday - 1;
    if (initialIndex > 5) initialIndex = 0; // Sunday -> Monday
    _tabController = TabController(length: 6, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        if (student == null || student.currentEnrollment == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Timetable'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('No enrollment found')),
          );
        }

        final sectionId = student.currentEnrollment!.sectionId;
        final timetableAsync = ref.watch(
          weeklyTimetableProvider(WeeklyTimetableFilter(sectionId: sectionId)),
        );

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
          body: timetableAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading timetable: $e')),
            data: (weeklyTimetable) => TabBarView(
              controller: _tabController,
              children: List.generate(6, (index) {
                final dayIndex = index + 1; // 1 = Monday
                final dayTimetable = weeklyTimetable.days.firstWhere(
                  (d) => d.dayOfWeek == dayIndex,
                  orElse: () => DayTimetable(dayOfWeek: dayIndex, dayName: _fullDays[index], entries: []),
                );
                final activeEntries = dayTimetable.entries.where((e) => e.subjectId != null).toList();
                if (activeEntries.isEmpty) {
                  return _buildEmptyDay(_fullDays[index]);
                }
                return _buildDayScheduleReal(activeEntries, _fullDays[index]);
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyDay(String day) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.weekend, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No classes on $day',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayScheduleReal(List<TimetableEntry> entries, String day) {
    // Sort by sequence order
    final sortedEntries = List<TimetableEntry>.from(entries)
      ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final isCurrentPeriod = _isCurrentPeriodReal(entry, day);
        
        return _TimetableEntryCard(
          entry: entry,
          isCurrentPeriod: isCurrentPeriod,
          periodIndex: index,
        );
      },
    );
  }

  bool _isCurrentPeriodReal(TimetableEntry entry, String day) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    
    if (currentDay != day) return false;
    
    final startTime = entry.startTime;
    final endTime = entry.endTime;
    
    if (startTime == null || endTime == null) return false;
    
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      final start = DateTime(now.year, now.month, now.day, 
        int.parse(startParts[0]), int.parse(startParts[1]));
      final end = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
      
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  Widget _buildDaySchedule(List<Map<String, dynamic>> entries, String day) {
    // Sort by period number
    final sortedEntries = List<Map<String, dynamic>>.from(entries)
      ..sort((a, b) => ((a['periodNumber'] as int?) ?? 0).compareTo((b['periodNumber'] as int?) ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final isCurrentPeriod = _isCurrentPeriod(entry, day);
        
        return _PeriodCard(
          entry: entry,
          isCurrentPeriod: isCurrentPeriod,
          periodIndex: index,
        );
      },
    );
  }

  bool _isCurrentPeriod(Map<String, dynamic> entry, String day) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    
    if (currentDay != day) return false;
    
    final startTimeStr = entry['startTime'] as String?;
    final endTimeStr = entry['endTime'] as String?;
    
    if (startTimeStr == null || endTimeStr == null) return false;
    
    try {
      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      
      final startTime = DateTime(now.year, now.month, now.day, 
        int.parse(startParts[0]), int.parse(startParts[1]));
      final endTime = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
      
      return now.isAfter(startTime) && now.isBefore(endTime);
    } catch (_) {
      return false;
    }
  }
}

class _PeriodCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isCurrentPeriod;
  final int periodIndex;

  const _PeriodCard({
    required this.entry,
    required this.isCurrentPeriod,
    required this.periodIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      Colors.purple,
      Colors.teal,
      Colors.orange,
    ];
    
    final color = colors[periodIndex % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isCurrentPeriod 
                    ? Border.all(color: AppColors.success, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  // Time Column
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatTime(entry['startTime'] as String?),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: color.withValues(alpha: 0.3),
                        ),
                        Text(
                          _formatTime(entry['endTime'] as String?),
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subject Details
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
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Period ${entry['periodNumber'] ?? (periodIndex + 1)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (entry['isBreak'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BREAK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry['subjectName'] as String? ?? 'Free Period',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (entry['teacherName'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  entry['teacherName'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (entry['roomNumber'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.room, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'Room ${entry['roomNumber']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'NOW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return '--:--';
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

class _TimetableEntryCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool isCurrentPeriod;
  final int periodIndex;

  const _TimetableEntryCard({
    required this.entry,
    required this.isCurrentPeriod,
    required this.periodIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      Colors.purple,
      Colors.teal,
      Colors.orange,
    ];
    
    final color = colors[periodIndex % colors.length];
    final isBreak = entry.slotType == 'break';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isCurrentPeriod 
                    ? Border.all(color: AppColors.success, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  // Time Column
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatTime(entry.startTime),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: color.withValues(alpha: 0.3),
                        ),
                        Text(
                          _formatTime(entry.endTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subject Details
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
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.slotName ?? 'Period ${periodIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (isBreak) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BREAK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.subjectName ?? 'Free Period',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (entry.teacherName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  entry.teacherName!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (entry.roomNumber != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.room, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'Room ${entry.roomNumber}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'NOW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return '--:--';
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
