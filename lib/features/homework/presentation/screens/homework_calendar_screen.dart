import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/homework.dart';
import '../../providers/homework_provider.dart';

class HomeworkCalendarScreen extends ConsumerStatefulWidget {
  const HomeworkCalendarScreen({super.key});

  @override
  ConsumerState<HomeworkCalendarScreen> createState() =>
      _HomeworkCalendarScreenState();
}

class _HomeworkCalendarScreenState
    extends ConsumerState<HomeworkCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  List<Homework> _selectedDayHomework = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    Future.microtask(() {
      ref.read(homeworkNotifierProvider.notifier).load();
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];

    // Add padding for first week
    final firstWeekday = first.weekday % 7; // Sunday = 0
    for (int i = firstWeekday; i > 0; i--) {
      days.add(first.subtract(Duration(days: i)));
    }

    // Add month days
    for (int i = 0; i < last.day; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }

    // Pad to complete last week
    final remaining = 7 - (days.length % 7);
    if (remaining < 7) {
      for (int i = 1; i <= remaining; i++) {
        days.add(DateTime(month.year, month.month + 1, i));
      }
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentMonth(DateTime day) {
    return day.month == _focusedMonth.month &&
        day.year == _focusedMonth.year;
  }

  int _homeworkCountForDay(DateTime day, List<Homework> allHomework) {
    return allHomework
        .where((hw) => _isSameDay(hw.dueDate, day))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthFormat = DateFormat('MMMM yyyy');
    final homeworkAsync = ref.watch(homeworkNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Calendar'),
      ),
      body: homeworkAsync.when(
        data: (allHomework) {
          final days = _getDaysInMonth(_focusedMonth);

          // Update selected day homework
          if (_selectedDate != null) {
            _selectedDayHomework = allHomework
                .where((hw) => _isSameDay(hw.dueDate, _selectedDate!))
                .toList();
          }

          return Column(
            children: [
              // Month navigation
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      monthFormat.format(_focusedMonth),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Day headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Calendar grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isToday = _isSameDay(day, DateTime.now());
                    final isSelected =
                        _selectedDate != null && _isSameDay(day, _selectedDate!);
                    final isInMonth = _isCurrentMonth(day);
                    final hwCount =
                        _homeworkCountForDay(day, allHomework);
                    final hasOverdue = allHomework.any((hw) =>
                        _isSameDay(hw.dueDate, day) && hw.isOverdue);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = day;
                          _selectedDayHomework = allHomework
                              .where((hw) => _isSameDay(hw.dueDate, day))
                              .toList();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : !isInMonth
                                        ? AppColors.textSecondaryLight
                                            .withValues(alpha: 0.4)
                                        : null,
                                fontWeight:
                                    isToday ? FontWeight.bold : null,
                              ),
                            ),
                            if (hwCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : hasOverdue
                                          ? AppColors.error
                                          : AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Selected day homework
              Expanded(
                child: _selectedDayHomework.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_available,
                                size: 48,
                                color: AppColors.textSecondaryLight),
                            const SizedBox(height: 8),
                            Text(
                              _selectedDate != null
                                  ? 'No homework due on ${DateFormat('MMM dd').format(_selectedDate!)}'
                                  : 'Select a date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _selectedDayHomework.length,
                        itemBuilder: (context, index) {
                          final hw = _selectedDayHomework[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              onTap: () => context.push('/homework/${hw.id}'),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: hw.priority == HomeworkPriority.high
                                          ? AppColors.error
                                          : hw.priority == HomeworkPriority.medium
                                              ? AppColors.accent
                                              : AppColors.success,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hw.title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${hw.subjectName ?? 'N/A'} | ${hw.className ?? ''} ${hw.sectionName ?? ''}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
