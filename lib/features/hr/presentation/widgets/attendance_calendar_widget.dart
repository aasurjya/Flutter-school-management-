import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/hr_payroll.dart';

/// Monthly calendar view of staff attendance
class AttendanceCalendarWidget extends StatelessWidget {
  final int year;
  final int month;
  final Map<int, StaffAttendanceStatus> dayStatusMap;

  const AttendanceCalendarWidget({
    super.key,
    required this.year,
    required this.month,
    this.dayStatusMap = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon, 7=Sun

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        Row(
          children: dayLabels.map((label) {
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        ..._buildWeeks(daysInMonth, startWeekday, context),

        const SizedBox(height: 12),

        // Legend
        const Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _LegendItem(color: AppColors.success, label: 'Present'),
            _LegendItem(color: AppColors.error, label: 'Absent'),
            _LegendItem(color: AppColors.warning, label: 'Half Day'),
            _LegendItem(color: AppColors.info, label: 'On Leave'),
            _LegendItem(color: AppColors.textTertiaryLight, label: 'Holiday'),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildWeeks(
      int daysInMonth, int startWeekday, BuildContext context) {
    final weeks = <Widget>[];
    int dayCounter = 1;

    // Up to 6 weeks
    for (int week = 0; week < 6; week++) {
      if (dayCounter > daysInMonth) break;

      final days = <Widget>[];
      for (int weekday = 1; weekday <= 7; weekday++) {
        if ((week == 0 && weekday < startWeekday) ||
            dayCounter > daysInMonth) {
          days.add(const Expanded(child: SizedBox(height: 36)));
        } else {
          final day = dayCounter;
          final status = dayStatusMap[day];
          days.add(
            Expanded(
              child: _DayCell(
                day: day,
                status: status,
                isToday: _isToday(day),
              ),
            ),
          );
          dayCounter++;
        }
      }

      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: days),
        ),
      );
    }

    return weeks;
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final StaffAttendanceStatus? status;
  final bool isToday;

  const _DayCell({
    required this.day,
    this.status,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Container(
      height: 36,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color?.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Color? get _statusColor {
    if (status == null) return null;
    switch (status!) {
      case StaffAttendanceStatus.present:
        return AppColors.success;
      case StaffAttendanceStatus.absent:
        return AppColors.error;
      case StaffAttendanceStatus.halfDay:
        return AppColors.warning;
      case StaffAttendanceStatus.onLeave:
        return AppColors.info;
      case StaffAttendanceStatus.holiday:
        return AppColors.textTertiaryLight;
    }
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withAlpha(80),
            borderRadius: BorderRadius.circular(3),
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
