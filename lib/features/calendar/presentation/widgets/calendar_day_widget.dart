import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';

/// Custom day builder for table_calendar showing event dots
class CalendarDayWidget extends StatelessWidget {
  final DateTime day;
  final DateTime focusedDay;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;
  final List<SchoolEvent> events;
  final bool isHoliday;

  const CalendarDayWidget({
    super.key,
    required this.day,
    required this.focusedDay,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
    this.events = const [],
    this.isHoliday = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color? backgroundColor;
    Color textColor;
    FontWeight fontWeight = FontWeight.normal;

    if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
      fontWeight = FontWeight.w600;
    } else if (isToday) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.15);
      textColor = AppColors.primary;
      fontWeight = FontWeight.w600;
    } else if (isOutside) {
      textColor = isDark
          ? AppColors.textTertiaryDark
          : AppColors.textTertiaryLight;
    } else if (isHoliday) {
      textColor = AppColors.error;
      fontWeight = FontWeight.w500;
    } else {
      textColor = isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight;
    }

    // Collect unique event type colors (max 3 dots)
    final dotColors = events
        .map((e) {
          final hex = (e.colorHex ?? e.eventType.colorHex).replaceFirst('#', '');
          return Color(int.parse('FF$hex', radix: 16));
        })
        .toSet()
        .take(3)
        .toList();

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
          if (dotColors.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dotColors.map((color) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : color,
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
