import 'package:flutter/material.dart';

import '../../../../data/models/discipline.dart';

class SeverityBadge extends StatelessWidget {
  final IncidentSeverity severity;
  final bool compact;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.compact = false,
  });

  Color get _color {
    switch (severity) {
      case IncidentSeverity.minor:
        return const Color(0xFF3B82F6); // blue
      case IncidentSeverity.moderate:
        return const Color(0xFFF59E0B); // amber
      case IncidentSeverity.major:
        return const Color(0xFFF97316); // orange
      case IncidentSeverity.critical:
        return const Color(0xFFEF4444); // red
    }
  }

  IconData get _icon {
    switch (severity) {
      case IncidentSeverity.minor:
        return Icons.info_outline;
      case IncidentSeverity.moderate:
        return Icons.warning_amber_rounded;
      case IncidentSeverity.major:
        return Icons.error_outline;
      case IncidentSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          severity.displayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            severity.displayLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final IncidentStatus status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case IncidentStatus.reported:
        return const Color(0xFF3B82F6);
      case IncidentStatus.investigating:
        return const Color(0xFFF59E0B);
      case IncidentStatus.resolved:
        return const Color(0xFF22C55E);
      case IncidentStatus.escalated:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
