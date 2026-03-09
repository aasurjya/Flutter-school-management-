import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/event_type_badge.dart';

/// Main calendar screen with month/week/day toggle using table_calendar
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _updateRange();
  }

  void _updateRange() {
    // Load a wider range so month transitions are smooth
    _rangeStart = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    _rangeEnd = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filterType = ref.watch(selectedEventTypeFilterProvider);

    final filter = CalendarFilter(
      startDate: _rangeStart,
      endDate: _rangeEnd,
      eventType: filterType,
    );
    final eventsAsync = ref.watch(eventsForRangeProvider(filter));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('School Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _updateRange();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by type',
            onPressed: () => _showFilterSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'events':
                  context.push('/calendar/events');
                  break;
                case 'academic':
                  context.push('/calendar/academic');
                  break;
                case 'holidays':
                  context.push('/calendar/holidays');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'events', child: Text('All Events')),
              const PopupMenuItem(
                  value: 'academic', child: Text('Academic Calendar')),
              const PopupMenuItem(
                  value: 'holidays', child: Text('Holiday Calendar')),
            ],
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load events',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text('$error', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        data: (events) => _buildBody(context, events),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/calendar/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<SchoolEvent> events) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build events map keyed by date
    final Map<DateTime, List<SchoolEvent>> eventMap = {};
    for (final event in events) {
      // Add to every day the event spans
      final end = event.endDate;
      for (var d = event.startDate;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        final key = DateTime(d.year, d.month, d.day);
        eventMap.putIfAbsent(key, () => []).add(event);
      }
    }

    final selectedKey =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final selectedEvents = eventMap[selectedKey] ?? [];

    return Column(
      children: [
        // Filter chips (if a filter is active)
        if (ref.watch(selectedEventTypeFilterProvider) != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                EventTypeBadge(
                  eventType: ref.watch(selectedEventTypeFilterProvider)!,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(selectedEventTypeFilterProvider.notifier)
                        .state = null;
                  },
                  child: const Icon(Icons.close, size: 18, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),

        // Calendar
        TableCalendar<SchoolEvent>(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _updateRange();
            });
            // Re-fetch for new range
            ref.invalidate(eventsForRangeProvider);
          },
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return eventMap[key] ?? [];
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            weekendTextStyle: TextStyle(
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markersMaxCount: 3,
            markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
            cellMargin: const EdgeInsets.all(4),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            titleTextStyle: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            weekendStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.error.withValues(alpha: 0.6),
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              final dotColors = events
                  .map((e) {
                    final hex =
                        (e.colorHex ?? e.eventType.colorHex)
                            .replaceFirst('#', '');
                    return Color(int.parse('FF$hex', radix: 16));
                  })
                  .toSet()
                  .take(3)
                  .toList();

              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: dotColors.map((color) {
                    return Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // Selected day header
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(_selectedDay),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        // Events list for selected day
        Expanded(
          child: selectedEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_available,
                        size: 48,
                        color: AppColors.textTertiaryLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No events on this day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];
                    return EventCard(
                      event: event,
                      showDate: false,
                      onTap: () =>
                          context.push('/calendar/event/${event.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter by Event Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(selectedEventTypeFilterProvider.notifier)
                          .state = null;
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EventType.values.map((type) {
                  final isActive =
                      ref.read(selectedEventTypeFilterProvider) == type;
                  return FilterChip(
                    label: Text(type.label),
                    selected: isActive,
                    onSelected: (selected) {
                      ref
                          .read(selectedEventTypeFilterProvider.notifier)
                          .state = selected ? type : null;
                      Navigator.pop(context);
                    },
                    avatar: Icon(
                      _typeIcon(type),
                      size: 16,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _typeIcon(EventType type) {
    switch (type) {
      case EventType.academic:
        return Icons.school;
      case EventType.cultural:
        return Icons.theater_comedy;
      case EventType.sports:
        return Icons.sports_soccer;
      case EventType.holiday:
        return Icons.beach_access;
      case EventType.exam:
        return Icons.quiz;
      case EventType.ptaMeeting:
        return Icons.groups;
      case EventType.workshop:
        return Icons.build;
      case EventType.fieldTrip:
        return Icons.directions_bus;
      case EventType.competition:
        return Icons.emoji_events;
      case EventType.celebration:
        return Icons.celebration;
    }
  }
}
