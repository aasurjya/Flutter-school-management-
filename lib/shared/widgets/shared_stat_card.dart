import 'package:flutter/material.dart';

/// A reusable stat card widget that displays a metric with an icon,
/// value, title, and optional trend indicator.
///
/// Replaces the duplicate _StatCard implementations found across
/// multiple feature screens (student detail, class analytics,
/// class students, student results, super admin dashboard, etc.).
class SharedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  /// Optional trend text (e.g., "+12%"). When provided, a trend badge
  /// is shown in the top-right corner.
  final String? trend;

  /// Optional trend color. Defaults to [Colors.green] when [trend] is set.
  final Color? trendColor;

  /// Padding inside the card. Defaults to `EdgeInsets.all(16)`.
  final EdgeInsets padding;

  /// Border radius. Defaults to 16.
  final double borderRadius;

  /// Icon size. Defaults to 24.
  final double iconSize;

  /// Value font size. Defaults to 18.
  final double valueFontSize;

  /// Title font size. Defaults to 11.
  final double titleFontSize;

  /// Whether to show a subtle border around the card. Defaults to false.
  final bool showBorder;

  /// Layout axis. When [Axis.vertical] (default), icon is above value.
  /// When [Axis.horizontal], icon is to the left of value/title.
  final Axis axis;

  const SharedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendColor,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.iconSize = 24,
    this.valueFontSize = 18,
    this.titleFontSize = 11,
    this.showBorder = false,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: color.withValues(alpha: 0.2))
            : null,
      ),
      child: axis == Axis.vertical
          ? _buildVerticalLayout()
          : _buildHorizontalLayout(),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      crossAxisAlignment:
          trend != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (trend != null)
          Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              const Spacer(),
              _buildTrendBadge(),
            ],
          )
        else
          Icon(icon, color: color, size: iconSize),
        if (trend != null) const SizedBox(height: 12) else const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        Icon(icon, color: color, size: iconSize),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (trend != null) _buildTrendBadge(),
      ],
    );
  }

  Widget _buildTrendBadge() {
    final badgeColor = trendColor ?? Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        trend!,
        style: TextStyle(fontSize: 10, color: badgeColor),
      ),
    );
  }
}
