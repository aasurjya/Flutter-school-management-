import 'package:flutter/material.dart';

import '../../../../data/models/early_warning_alert.dart';

/// A small colored badge widget showing alert severity level.
///
/// Displays the severity label in uppercase with a tinted background
/// matching the severity color from [AlertSeverity.color].
class AlertSeverityBadge extends StatelessWidget {
  final AlertSeverity severity;
  final double? fontSize;

  const AlertSeverityBadge({
    super.key,
    required this.severity,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = severity.color;
    final effectiveFontSize = fontSize ?? 11;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        severity.displayLabel.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: effectiveFontSize,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
