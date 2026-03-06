import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

/// A compact mini calendar widget for dashboards and sidebars
class MiniCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final Set<DateTime>? markedDates;
  final Set<DateTime>? holidayDates;

  const MiniCalendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.markedDates,
    this.holidayDates,
  });

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late DateTime _currentMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedDate ?? DateTime.now();
    _currentMonth = DateTime(_selected.year, _selected.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: month + nav arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left, size: 20),
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, size: 20),
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Day headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 4),

          // Day grid
          ..._buildWeeks(context),
        ],
      ),
    );
  }

  List<Widget> _buildWeeks(BuildContext context) {
    // First day of the month
    final firstDay = _currentMonth;
    // Day of week (1=Mon...7=Sun)
    int startWeekday = firstDay.weekday; // 1-7
    // Last day of month
    final lastDay =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Build cells starting from Monday
    final cells = <Widget>[];
    // Pad before
    final prevMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 0);
    for (int i = startWeekday - 1; i > 0; i--) {
      final d = prevMonth.day - i + 1;
      cells.add(_buildDayCell(
        context,
        DateTime(prevMonth.year, prevMonth.month, d),
        isOutside: true,
      ));
    }
    // Actual days
    for (int d = 1; d <= lastDay.day; d++) {
      cells.add(_buildDayCell(
        context,
        DateTime(_currentMonth.year, _currentMonth.month, d),
      ));
    }
    // Pad after
    final remaining = 7 - (cells.length % 7);
    if (remaining < 7) {
      for (int i = 1; i <= remaining; i++) {
        cells.add(_buildDayCell(
          context,
          DateTime(lastDay.year, lastDay.month + 1, i),
          isOutside: true,
        ));
      }
    }

    // Group into weeks
    final weeks = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      weeks.add(
        Row(children: cells.sublist(i, i + 7)),
      );
    }
    return weeks;
  }

  Widget _buildDayCell(BuildContext context, DateTime date,
      {bool isOutside = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isSelected = date.year == _selected.year &&
        date.month == _selected.month &&
        date.day == _selected.day;
    final normalized = DateTime(date.year, date.month, date.day);
    final hasEvent = widget.markedDates?.contains(normalized) ?? false;
    final isHoliday = widget.holidayDates?.contains(normalized) ?? false;

    Color textColor;
    Color? bgColor;

    if (isSelected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = AppColors.primary.withValues(alpha: 0.1);
      textColor = AppColors.primary;
    } else if (isOutside) {
      textColor = isDark
          ? AppColors.textTertiaryDark
          : AppColors.textTertiaryLight;
    } else if (isHoliday) {
      textColor = AppColors.error;
    } else {
      textColor = isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight;
    }

    return Expanded(
      child: GestureDetector(
        onTap: isOutside
            ? null
            : () {
                setState(() => _selected = date);
                widget.onDateSelected?.call(date);
              },
        child: Container(
          height: 32,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isToday || isSelected ? FontWeight.w600 : null,
                  color: textColor,
                ),
              ),
              if (hasEvent)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
