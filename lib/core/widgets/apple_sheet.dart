import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';

/// Canonical Apple-style bottom sheet.
///
/// Replaces ad-hoc `showModalBottomSheet` calls across the app. Why this exists:
/// - Consistent drag handle + grouped background.
/// - Optional large title that doesn't fight the content.
/// - Motion.transition timing instead of Material's faster default.
/// - Safe-area padded; content scrolls inside the sheet, not under it.
/// - Optional `actions` row at the bottom (the "action sheet" pattern).
///
/// Returns whatever the inner Navigator pops (or null on dismiss).
Future<T?> showAppleSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
  String? title,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.4),
    backgroundColor: Colors.transparent,
    elevation: 0,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: Motion.transition,
      reverseDuration: Motion.subtle,
    ),
    builder: (ctx) => _AppleSheetContainer(title: title, child: Builder(builder: builder)),
  );
}

class _AppleSheetContainer extends StatelessWidget {
  const _AppleSheetContainer({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = AppColors.groupedBackgroundFor(brightness);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            if (title != null) _SheetTitle(title: title!),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.labelFor(brightness, tier: 3),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.displaySmall, // Title 2 (22pt)
      ),
    );
  }
}

/// Action-sheet helper — the iOS pattern where the user picks one of N
/// destructive/neutral options. Use this in place of confirmation
/// `showDialog`s for cleaner flows.
///
/// Returns the index of the tapped action, or null if dismissed.
Future<int?> showAppleActionSheet(
  BuildContext context, {
  String? title,
  String? message,
  required List<AppleSheetAction> actions,
  String cancelLabel = 'Cancel',
}) {
  return showAppleSheet<int>(
    context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final brightness = theme.brightness;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || message != null) ...[
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.labelFor(brightness, tier: 2),
                  ),
                ),
              ),
          ],
          for (var i = 0; i < actions.length; i++) ...[
            _ActionButton(
              label: actions[i].label,
              destructive: actions[i].destructive,
              onTap: () => Navigator.of(ctx).pop(i),
            ),
            if (i < actions.length - 1) const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          _ActionButton(
            label: cancelLabel,
            isCancel: true,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      );
    },
  );
}

class AppleSheetAction {
  final String label;
  final bool destructive;
  const AppleSheetAction(this.label, {this.destructive = false});
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.isCancel = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool isCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final color = destructive
        ? AppColors.error
        : (isCancel
            ? AppColors.labelFor(brightness, tier: 1)
            : (brightness == Brightness.dark ? AppColors.tintDark : AppColors.tint));

    return Material(
      color: AppColors.groupedCellFor(brightness),
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.separatorFor(brightness),
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: isCancel ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
