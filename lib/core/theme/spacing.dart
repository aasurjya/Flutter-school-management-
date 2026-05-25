import 'package:flutter/widgets.dart';

/// Single-source spacing scale.
///
/// 4-point grid; no off-grid values allowed in new code. The ux-grid-reviewer
/// agent enforces this — any `EdgeInsets` literal that doesn't add up from
/// these constants is a violation.
class AppSpacing {
  AppSpacing._();

  /// 4 — hairline insets, icon-to-label nudges.
  static const double xxs = 4;

  /// 8 — tight rows, chip gaps.
  static const double xs = 8;

  /// 12 — between siblings in a row, between text lines in a card.
  static const double sm = 12;

  /// 16 — default content padding, between sections in a list.
  static const double md = 16;

  /// 24 — between major regions (hero → list).
  static const double lg = 24;

  /// 32 — generous breathing room between blocks.
  static const double xl = 32;

  /// 48 — between hero and footer, between modal title and body.
  static const double xxl = 48;

  // ---- Convenience EdgeInsets (the ~5 most common ones) ----
  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pageHV = EdgeInsets.symmetric(horizontal: md, vertical: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(md, lg, md, xl);

  // ---- Common SizedBoxes (avoid allocating per build) ----
  static const SizedBox gapXxs = SizedBox(height: xxs, width: xxs);
  static const SizedBox gapXs  = SizedBox(height: xs,  width: xs);
  static const SizedBox gapSm  = SizedBox(height: sm,  width: sm);
  static const SizedBox gapMd  = SizedBox(height: md,  width: md);
  static const SizedBox gapLg  = SizedBox(height: lg,  width: lg);
  static const SizedBox gapXl  = SizedBox(height: xl,  width: xl);
}

/// Single-source shape (radii) scale.
class AppRadius {
  AppRadius._();

  /// 6 — chips, tags, badges.
  static const double xs = 6;

  /// 10 — cards (Apple uses 10pt; we mirror).
  static const double sm = 10;

  /// 12 — buttons, segmented controls.
  static const double md = 12;

  /// 16 — sheets, large cards.
  static const double lg = 16;

  /// 24 — pill / capsule.
  static const double pill = 999;

  static const BorderRadius chip   = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius card   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet  = BorderRadius.vertical(top: Radius.circular(lg));
}
