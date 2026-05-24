import 'package:flutter/material.dart';

import '../copy/warm_strings.dart';
import '../theme/app_colors.dart';

/// Apple-style "saved with undo" affordance.
///
/// Replaces "Are you sure?" confirmation dialogs. Pattern stolen from iOS
/// Mail/Notes: the destructive write happens immediately, the user gets a
/// short window to take it back, and silence after the window means commit.
///
/// Use [UndoBanner.show] from any callback that just persisted a change a
/// human might regret. Pairs with a snapshot taken *before* the write so the
/// undo can restore byte-for-byte.
class UndoBanner {
  UndoBanner._();

  /// Default time the banner stays visible.
  ///
  /// Long enough for an "oh no" reaction, short enough that it never feels
  /// like a modal. Mirrors iOS Mail's archive toast.
  static const Duration defaultDuration = Duration(seconds: 6);

  /// Show an undo banner anchored above the bottom nav / safe area.
  ///
  /// [message] should be a complete declarative sentence — e.g. "Attendance saved."
  /// [onUndo] is the revert handler. It is NOT called if the banner times out.
  ///
  /// Returns a [ScaffoldFeatureController] so callers can dismiss it early
  /// (e.g. when the user navigates away).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = defaultDuration,
    String actionLabel = WarmCopy.undoAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.label, // near-black, calm
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        duration: duration,
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.labelDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: SnackBarAction(
          label: actionLabel,
          textColor: AppColors.labelDark,
          onPressed: onUndo,
        ),
      ),
    );
  }
}
