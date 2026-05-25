import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Apple Settings-style grouped section.
///
/// Renders the iOS pattern:
///
///   SECTION HEADER (small, secondary)
///   ┌────────────────────────────────────┐
///   │ Cell title           value  >      │
///   │ ─── (hairline) ─────────────────── │
///   │ Cell title                          │
///   └────────────────────────────────────┘
///
/// Use this in place of card grids on dashboards. One section = one task
/// cluster. Cells inside are connected — they share a single rounded
/// surface, separated only by hairlines.
class AppleListSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const AppleListSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final separator = AppColors.separatorFor(brightness);
    final cellColor = AppColors.groupedCellFor(brightness);

    // Interleave hairlines between cells.
    final List<Widget> cells = [];
    for (var i = 0; i < children.length; i++) {
      cells.add(children[i]);
      if (i < children.length - 1) {
        cells.add(_Hairline(color: separator));
      }
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) _SectionLabel(text: header!, brightness: brightness),
          ClipRRect(
            borderRadius: AppRadius.card,
            child: Container(
              color: cellColor,
              child: Column(children: cells),
            ),
          ),
          if (footer != null) _SectionFooter(text: footer!, brightness: brightness),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.brightness});

  final String text;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          color: AppColors.labelFor(brightness, tier: 2),
        ),
      ),
    );
  }
}

class _SectionFooter extends StatelessWidget {
  const _SectionFooter({required this.text, required this.brightness});

  final String text;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          color: AppColors.labelFor(brightness, tier: 3),
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Container(height: 0.5, color: color),
    );
  }
}

/// A single Apple-style cell. Tappable when [onTap] is provided.
///
/// Layout:
///   [leading]  title             [value]  [chevron]
///              subtitle
class AppleListCell extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? titleColor;
  final bool destructive;

  const AppleListCell({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.titleColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final secondary = AppColors.labelFor(brightness, tier: 2);
    final resolvedTitleColor = destructive
        ? AppColors.error
        : (titleColor ?? AppColors.labelFor(brightness, tier: 1));

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            SizedBox(width: 28, height: 28, child: Center(child: leading!)),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(color: resolvedTitleColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              value!,
              style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.xxs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.labelFor(brightness, tier: 3),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.separatorFor(brightness),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: content,
        ),
      ),
    );
  }
}

/// A cell that hosts a switch on the right, as iOS Settings does.
class AppleListSwitchCell extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppleListSwitchCell({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppleListCell(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}
