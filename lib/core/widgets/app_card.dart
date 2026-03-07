import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Premium flat card — elevation 0, subtle background shift for depth.
///
/// Use [AppCard] everywhere instead of [Card] or raw [Container] wrappers.
/// Supports tap ripple via [Material] + [InkWell].
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.radius = 16,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFF8F9FA);

    return Material(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Container(
          decoration: border != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: border,
                )
              : null,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A [AppCard] variant that highlights a single key metric.
///
/// Displays a large [value], a [label] beneath it, and an optional
/// accent [color] dot / left border.
class AppStatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? sublabel;
  final IconData? icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    this.sublabel,
    this.icon,
    this.accentColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            value,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sublabel!,
              style: tt.labelSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A horizontal info row inside a card — icon + label + trailing value.
class AppCardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const AppCardRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(color: AppColors.grey700),
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
