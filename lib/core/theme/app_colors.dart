import 'package:flutter/material.dart';

/// Application color palette — premium monochromatic design system
/// Inspired by Linear, Vercel, Notion: black/white/grey with semantic accents only
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY — jet black (authority, clarity)
  // ============================================
  static const Color primary      = Color(0xFF111827); // grey-900 — THE primary action color
  static const Color primaryLight = Color(0xFFF3F4F6); // grey-100 — primary tint
  static const Color primaryDark  = Color(0xFF000000); // pure black — pressed state

  // Secondary actions use grey-600
  static const Color secondary      = Color(0xFF4B5563); // grey-600
  static const Color secondaryLight = Color(0xFFF9FAFB); // grey-50
  static const Color secondaryDark  = Color(0xFF1F2937);  // grey-800

  // Accent kept subtle — grey-700
  static const Color accent      = Color(0xFF374151); // grey-700
  static const Color accentLight = Color(0xFFF3F4F6); // grey-100
  static const Color accentDark  = Color(0xFF111827); // grey-900

  // ============================================
  // SEMANTIC — keep full color ONLY for status
  // ============================================
  static const Color success      = Color(0xFF16A34A); // green-600
  static const Color successLight = Color(0xFFDCFCE7); // green-50
  static const Color error        = Color(0xFFDC2626); // red-600
  static const Color errorLight   = Color(0xFFFEE2E2); // red-50
  static const Color warning      = Color(0xFFD97706); // amber-600
  static const Color warningLight = Color(0xFFFEF3C7); // amber-50
  static const Color info         = Color(0xFF0284C7); // sky-600
  static const Color infoLight    = Color(0xFFE0F2FE); // sky-50

  // ============================================
  // NEUTRALS — full Tailwind grey scale
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
  // BACKGROUND / SURFACE
  // ============================================
  static const Color background      = Color(0xFFFFFFFF); // pure white
  static const Color surface         = Color(0xFFF9FAFB); // grey-50
  static const Color surfaceElevated = Color(0xFFF3F4F6); // grey-100

  // Legacy aliases
  static const Color backgroundLight = surface;
  static const Color backgroundDark  = Color(0xFF0F172A);
  static const Color surfaceLight    = background;
  static const Color surfaceDark     = Color(0xFF1E293B);
  static const Color cardLight       = background;
  static const Color cardDark        = Color(0xFF1E293B);

  // ============================================
  // TEXT
  // ============================================
  static const Color textPrimaryLight   = grey900; // #111827
  static const Color textSecondaryLight = grey500; // #6B7280
  static const Color textTertiaryLight  = grey400; // #9CA3AF

  static const Color textPrimaryDark    = Color(0xFFF8FAFC);
  static const Color textSecondaryDark  = Color(0xFF94A3B8);
  static const Color textTertiaryDark   = Color(0xFF64748B);

  // ============================================
  // BORDERS & DIVIDERS
  // ============================================
  static const Color borderLight  = grey200;
  static const Color borderDark   = Color(0xFF334155);
  static const Color dividerLight = grey200;
  static const Color dividerDark  = Color(0xFF334155);

  // ============================================
  // INPUTS
  // ============================================
  static const Color inputFillLight = grey50;
  static const Color inputFillDark  = Color(0xFF1E293B);

  // ============================================
  // ATTENDANCE STATUS
  // ============================================
  static const Color present = success;
  static const Color absent  = error;
  static const Color late    = warning;
  static const Color excused = info;
  static const Color halfDay = Color(0xFF8B5CF6);

  // ============================================
  // GRADE COLORS
  // ============================================
  static const Color gradeA = success;
  static const Color gradeB = Color(0xFF0284C7); // sky — keep for grade distinction
  static const Color gradeC = warning;
  static const Color gradeD = Color(0xFFF97316); // orange
  static const Color gradeF = error;

  // ============================================
  // ROLE COLORS — subtle left-border only
  // ============================================
  static const Color adminColor   = grey900;
  static const Color teacherColor = grey700;
  static const Color studentColor = grey600;
  static const Color parentColor  = grey500;
  static const Color staffColor   = grey400;

  // ============================================
  // GLASS (legacy)
  // ============================================
  static const Color glassLight        = Color(0x80FFFFFF);
  static const Color glassDark         = Color(0x40000000);
  static const Color glassOverlayLight = Color(0x1AFFFFFF);
  static const Color glassOverlayDark  = Color(0x1A000000);

  // ============================================
  // GRADIENTS — monochrome only
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

  // Keep semantic gradients for charts/data
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
      case 'present': return present;
      case 'absent':  return absent;
      case 'late':    return late;
      case 'excused': return excused;
      case 'half_day': return halfDay;
      default: return textSecondaryLight;
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
      case 'super_admin': case 'tenant_admin': case 'principal': return adminColor;
      case 'teacher':  return teacherColor;
      case 'student':  return studentColor;
      case 'parent':   return parentColor;
      default:         return staffColor;
    }
  }
}
