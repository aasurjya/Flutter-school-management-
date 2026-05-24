import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// "GlassCard" — historical name kept for API compatibility, now a calm
/// Apple-style grouped surface: solid fill, hairline separator, no blur,
/// no shadow. The BackdropFilter blur was a measured ~3x GPU cost on
/// low-end Android and contributed nothing to clarity.
///
/// The constructor still accepts `blur`, `borderColor`, `borderWidth`,
/// `boxShadow`, `gradient` — they're silently ignored so existing call
/// sites compile unchanged. Schedule them for removal in a follow-up
/// refactor PR once feature screens migrate to direct widgets.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Gradient? gradient; // retained for GradientGlassCard contract

  // Deprecated visual knobs — ignored, kept for source compat.
  @Deprecated('BackdropFilter removed in Phase 0. Will be deleted in a follow-up.')
  final double blur;
  @Deprecated('Border is now a hairline. Will be deleted in a follow-up.')
  final Color? borderColor;
  @Deprecated('Border width is now fixed at 0.5. Will be deleted in a follow-up.')
  final double borderWidth;
  @Deprecated('Cards no longer ship with a default shadow. Will be deleted in a follow-up.')
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 10,
    this.blur = 0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fill = backgroundColor ?? AppColors.groupedCellFor(brightness);
    final radius = BorderRadius.circular(borderRadius);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        borderRadius: radius,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: AppColors.separatorFor(brightness),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// Gradient variant — kept for chart cards and onboarding flourishes.
/// Most feature code should NOT reach for this — the default solid
/// GlassCard is the calm choice.
class GradientGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Gradient gradient;
  final VoidCallback? onTap;

  const GradientGlassCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      onTap: onTap,
      gradient: gradient,
      backgroundColor: Colors.transparent,
      child: child,
    );
  }
}

/// Stat card — value + label + icon on the grouped surface.
/// Visual changes (Phase 0):
///   - No tint-tinted icon backdrop (was using primary.withValues(alpha: 0.1)).
///   - Headline weight follows the new Apple HIG scale.
///   - No shadow.
class GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? trailing;

  const GlassStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.gradient,
    this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final colorScheme = theme.colorScheme;
    final iconCol = iconColor ?? colorScheme.primary;
    final onGradient = gradient != null;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: onGradient ? Colors.white : iconCol,
                size: 22,
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              color: onGradient ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onGradient
                  ? Colors.white.withValues(alpha: 0.85)
                  : AppColors.labelFor(brightness, tier: 2),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onGradient
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.labelFor(brightness, tier: 3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
