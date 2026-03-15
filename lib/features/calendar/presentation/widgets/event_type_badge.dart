import 'package:flutter/material.dart';

import '../../../../data/models/school_event.dart';

/// A color-coded badge showing event type
class EventTypeBadge extends StatelessWidget {
  final EventType eventType;
  final bool compact;

  const EventTypeBadge({
    super.key,
    required this.eventType,
    this.compact = false,
  });

  Color get _color => _colorFromHex(eventType.colorHex);

  static Color _colorFromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  IconData get _icon {
    switch (eventType) {
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

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_icon, size: 16, color: _color),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            eventType.label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
