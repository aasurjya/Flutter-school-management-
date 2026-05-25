import 'package:flutter/material.dart';

/// Application color palette — Apple-style calm system palette.
///
/// Mental model: iOS Human Interface Guidelines + grayscale brand neutrality.
/// - Backgrounds are layered (system / secondary / tertiary) the way Settings is.
/// - Labels follow the iOS 4-tier hierarchy.
/// - Separators are hairlines, not borders.
/// - The single brand `tint` is grayscale (#111827) — semantic colors stay
///   reserved for true status (success/error/warning).
///
/// Legacy AppColors.* names are preserved as aliases so existing screens keep
/// building. New code should prefer the Apple-named tokens.
class AppColors {
  AppColors._();

  // ============================================
  // APPLE SYSTEM BACKGROUNDS (light / dark)
  // ============================================
  /// Top-most background — the scaffold canvas.
  static const Color systemBackground          = Color(0xFFFFFFFF);
  static const Color systemBackgroundDark      = Color(0xFF000000);

  /// One step elevated — used on grouped table screens (the Settings pattern).
  static const Color secondarySystemBackground     = Color(0xFFF2F2F7);
  static const Color secondarySystemBackgroundDark = Color(0xFF1C1C1E);

  /// Two steps elevated — used for cells inside grouped surfaces.
  static const Color tertiarySystemBackground      = Color(0xFFFFFFFF);
  static const Color tertiarySystemBackgroundDark  = Color(0xFF2C2C2E);

  // Grouped surface aliases (Settings-style cell backgrounds)
  static const Color systemGroupedBackground       = Color(0xFFF2F2F7);
  static const Color systemGroupedBackgroundDark   = Color(0xFF000000);
  static const Color secondaryGroupedBackground    = Color(0xFFFFFFFF);
  static const Color secondaryGroupedBackgroundDark = Color(0xFF1C1C1E);
  static const Color tertiaryGroupedBackground     = Color(0xFFF2F2F7);
  static const Color tertiaryGroupedBackgroundDark = Color(0xFF2C2C2E);

  // ============================================
  // APPLE LABEL HIERARCHY (text on light/dark)
  // ============================================
  /// Primary text. iOS uses pure black at full opacity.
  static const Color label              = Color(0xFF000000);
  static const Color labelDark          = Color(0xFFFFFFFF);

  /// Secondary text — same hue, ~60% prominence.
  static const Color secondaryLabel     = Color(0x993C3C43); // 60% black
  static const Color secondaryLabelDark = Color(0x99EBEBF5);

  /// Tertiary — captions, helper text.
  static const Color tertiaryLabel      = Color(0x4D3C3C43); // 30% black
  static const Color tertiaryLabelDark  = Color(0x4DEBEBF5);

  /// Quaternary — disabled, faint.
  static const Color quaternaryLabel    = Color(0x2E3C3C43);
  static const Color quaternaryLabelDark = Color(0x2EEBEBF5);

  /// Placeholder text — inside text fields.
  static const Color placeholderText    = Color(0x4D3C3C43);
  static const Color placeholderTextDark = Color(0x4DEBEBF5);

  // ============================================
  // APPLE HAIRLINES / SEPARATORS
  // ============================================
  /// Translucent separator under list cells.
  static const Color separator     = Color(0x49545458); // 28% gray
  static const Color separatorDark = Color(0x99545458);

  /// Opaque separator — for nav bar bottom edges.
  static const Color opaqueSeparator     = Color(0xFFC6C6C8);
  static const Color opaqueSeparatorDark = Color(0xFF38383A);

  // ============================================
  // BRAND TINT (grayscale neutrality)
  // ============================================
  /// The single tint. Buttons, active nav icons, focus rings all use this.
  static const Color tint     = Color(0xFF111827);
  static const Color tintDark = Color(0xFFF8FAFC);

  // ============================================
  // LEGACY ALIASES — kept so existing ~4,200 refs keep building.
  // New code should prefer the Apple-named tokens above.
  // ============================================
  static const Color primary      = tint;          // #111827
  static const Color primaryLight = Color(0xFFF3F4F6);
  static const Color primaryDark  = Color(0xFF000000);

  static const Color secondary      = Color(0xFF4B5563);
  static const Color secondaryLight = Color(0xFFF9FAFB);
  static const Color secondaryDark  = Color(0xFF1F2937);

  static const Color accent      = Color(0xFF374151);
  static const Color accentLight = Color(0xFFF3F4F6);
  static const Color accentDark  = Color(0xFF111827);

  // ============================================
  // SEMANTIC — reserved for true status only.
  // Calmer values than before; WCAG AA preserved.
  // ============================================
  static const Color success      = Color(0xFF15803D);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error        = Color(0xFFDC2626);
  static const Color errorLight   = Color(0xFFFEE2E2);
  static const Color warning      = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info         = Color(0xFF0369A1);
  static const Color infoLight    = Color(0xFFE0F2FE);

  // ============================================
  // NEUTRALS — full grey scale (Tailwind-compat)
  // ============================================
  static const Color grey50  = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ============================================
  // BACKGROUND / SURFACE — legacy aliases mapped to Apple tokens
  // ============================================
  static const Color background      = systemBackground;
  static const Color surface         = secondarySystemBackground;
  static const Color surfaceElevated = tertiarySystemBackground;

  static const Color backgroundLight = surface;
  static const Color backgroundDark  = systemBackgroundDark;
  static const Color surfaceLight    = background;
  static const Color surfaceDark     = secondarySystemBackgroundDark;
  static const Color cardLight       = secondaryGroupedBackground;
  static const Color cardDark        = secondaryGroupedBackgroundDark;

  // ============================================
  // TEXT — legacy aliases
  // ============================================
  static const Color textPrimaryLight   = grey900;
  static const Color textSecondaryLight = grey600;
  static const Color textTertiaryLight  = grey500;

  static const Color textPrimaryDark    = Color(0xFFF8FAFC);
  static const Color textSecondaryDark  = Color(0xFFCBD5E1);
  static const Color textTertiaryDark   = Color(0xFF94A3B8);

  // ============================================
  // BORDERS & DIVIDERS — now mapped to hairline separators
  // ============================================
  static const Color borderLight  = opaqueSeparator;
  static const Color borderDark   = opaqueSeparatorDark;
  static const Color dividerLight = opaqueSeparator;
  static const Color dividerDark  = opaqueSeparatorDark;

  // ============================================
  // INPUTS
  // ============================================
  static const Color inputFillLight = secondarySystemBackground;
  static const Color inputFillDark  = secondarySystemBackgroundDark;

  // ============================================
  // ATTENDANCE STATUS (reserved semantic use)
  // ============================================
  static const Color present = success;
  static const Color absent  = error;
  static const Color late    = warning;
  static const Color excused = info;
  static const Color halfDay = Color(0xFF0F766E);

  // ============================================
  // GRADE COLORS
  // ============================================
  static const Color gradeA = success;
  static const Color gradeB = Color(0xFF0369A1);
  static const Color gradeC = warning;
  static const Color gradeD = Color(0xFFC2410C);
  static const Color gradeF = error;

  // ============================================
  // ROLE COLORS — collapsed onto a single neutral tint per Apple-style consistency.
  // Visually identical so users don't perceive "role color theming".
  // ============================================
  static const Color adminColor   = tint;
  static const Color teacherColor = tint;
  static const Color studentColor = tint;
  static const Color parentColor  = tint;
  static const Color staffColor   = tint;

  // ============================================
  // GLASS (legacy — kept so GlassCard fallbacks compile; new theme is calm-surface)
  // ============================================
  static const Color glassLight        = Color(0x80FFFFFF);
  static const Color glassDark         = Color(0x40000000);
  static const Color glassOverlayLight = Color(0x1AFFFFFF);
  static const Color glassOverlayDark  = Color(0x1A000000);

  // ============================================
  // GRADIENTS — kept as legacy symbols. Discouraged in new code.
  // (Phase 2 dashboards will stop referencing these in heroes.)
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [grey900, grey700],
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [grey700, grey500],
  );
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [grey800, grey600],
  );
  static const LinearGradient sunriseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB7185), Color(0xFFFBBF24)],
  );
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );
  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF14B8A6)],
  );

  // ============================================
  // HELPER METHODS
  // ============================================
  static Color attendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':  return present;
      case 'absent':   return absent;
      case 'late':     return late;
      case 'excused':  return excused;
      case 'half_day': return halfDay;
      default:         return textSecondaryLight;
    }
  }

  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+': case 'A': return gradeA;
      case 'B+': case 'B': return gradeB;
      case 'C+': case 'C': return gradeC;
      case 'D':            return gradeD;
      case 'F':            return gradeF;
      default:             return textSecondaryLight;
    }
  }

  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'tenant_admin':
      case 'principal':
        return adminColor;
      case 'teacher': return teacherColor;
      case 'student': return studentColor;
      case 'parent':  return parentColor;
      default:        return staffColor;
    }
  }

  /// Brightness-aware label color (Apple hierarchy).
  static Color labelFor(Brightness b, {int tier = 1}) {
    final dark = b == Brightness.dark;
    switch (tier) {
      case 1: return dark ? labelDark : label;
      case 2: return dark ? secondaryLabelDark : secondaryLabel;
      case 3: return dark ? tertiaryLabelDark : tertiaryLabel;
      case 4: return dark ? quaternaryLabelDark : quaternaryLabel;
      default: return dark ? labelDark : label;
    }
  }

  /// Brightness-aware grouped surface background.
  static Color groupedBackgroundFor(Brightness b) =>
      b == Brightness.dark ? systemGroupedBackgroundDark : systemGroupedBackground;

  /// Brightness-aware cell background (inside grouped lists).
  static Color groupedCellFor(Brightness b) =>
      b == Brightness.dark ? secondaryGroupedBackgroundDark : secondaryGroupedBackground;

  /// Brightness-aware hairline separator.
  static Color separatorFor(Brightness b) =>
      b == Brightness.dark ? separatorDark : separator;
}
