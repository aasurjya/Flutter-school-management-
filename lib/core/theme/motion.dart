import 'package:flutter/widgets.dart';

/// Single-source motion vocabulary.
///
/// Apple's motion language is small and predictable. Four named tokens cover
/// >95% of interactions — anything else is a localized exception and should
/// be justified.
class Motion {
  Motion._();

  // ----- Durations -----
  /// 150ms — button presses, toggle flips, micro state.
  static const Duration tap = Duration(milliseconds: 150);

  /// 220ms — state changes inside a screen (e.g. tab indicator slide).
  static const Duration subtle = Duration(milliseconds: 220);

  /// 350ms — full transitions: routes, modal sheets, fullscreen presentations.
  static const Duration transition = Duration(milliseconds: 350);

  /// 500ms — large reveal animations that should feel deliberate, not instant.
  static const Duration deliberate = Duration(milliseconds: 500);

  // ----- Curves -----
  /// Apple's primary curve. Used on iOS for sheet presentations and most
  /// system transitions. Smooth deceleration, slight overshoot resistance.
  static const Curve standard = Cubic(0.32, 0.72, 0, 1);

  /// Sharper deceleration — for tap feedback and lighter state changes.
  static const Curve tapCurve = Curves.easeOut;

  /// Symmetric — for content fades and cross-dissolves.
  static const Curve subtleCurve = Curves.easeInOut;

  // ----- Spring (interactive drag dismiss, scroll bounce) -----
  /// Tuned to feel like iOS's drag-to-dismiss sheet — stiff enough to track
  /// the finger, soft enough to settle without bounce overshoot.
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 250,
    damping: 28,
  );

  // ----- Convenience builders -----
  /// Fade transition with the standard curve + transition duration.
  /// Pass to `PageRouteBuilder.transitionsBuilder` if needed.
  static Widget fadeTransition(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: standard);
    return FadeTransition(opacity: curved, child: child);
  }

  /// Slide-up from bottom — the iOS sheet presentation.
  static Widget slideUp(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: standard);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}
