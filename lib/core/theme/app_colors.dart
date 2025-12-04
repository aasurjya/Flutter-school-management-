import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ============================================
  // BACKGROUND COLORS
  // ============================================
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // ============================================
  // BORDER & DIVIDER COLORS
  // ============================================
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // ============================================
  // INPUT COLORS
  // ============================================
  static const Color inputFillLight = Color(0xFFF1F5F9);
  static const Color inputFillDark = Color(0xFF1E293B);

  // ============================================
  // ATTENDANCE STATUS COLORS
  // ============================================
  static const Color present = Color(0xFF22C55E);
  static const Color absent = Color(0xFFEF4444);
  static const Color late = Color(0xFFF59E0B);
  static const Color excused = Color(0xFF3B82F6);
  static const Color halfDay = Color(0xFF8B5CF6);

  // ============================================
  // GRADE COLORS
  // ============================================
  static const Color gradeA = Color(0xFF22C55E);
  static const Color gradeB = Color(0xFF3B82F6);
  static const Color gradeC = Color(0xFFF59E0B);
  static const Color gradeD = Color(0xFFF97316);
  static const Color gradeF = Color(0xFFEF4444);

  // ============================================
  // ROLE COLORS
  // ============================================
  static const Color adminColor = Color(0xFF8B5CF6);
  static const Color teacherColor = Color(0xFF3B82F6);
  static const Color studentColor = Color(0xFF22C55E);
  static const Color parentColor = Color(0xFFF59E0B);
  static const Color staffColor = Color(0xFF64748B);

  // ============================================
  // GLASSMORPHISM COLORS
  // ============================================
  static const Color glassLight = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x40000000);
  static const Color glassOverlayLight = Color(0x1AFFFFFF);
  static const Color glassOverlayDark = Color(0x1A000000);

  // ============================================
  // GRADIENT PRESETS
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
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
      case 'present':
        return present;
      case 'absent':
        return absent;
      case 'late':
        return late;
      case 'excused':
        return excused;
      case 'half_day':
        return halfDay;
      default:
        return textSecondaryLight;
    }
  }

  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return gradeA;
      case 'B+':
      case 'B':
        return gradeB;
      case 'C+':
      case 'C':
        return gradeC;
      case 'D':
        return gradeD;
      case 'F':
        return gradeF;
      default:
        return textSecondaryLight;
    }
  }

  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'tenant_admin':
      case 'principal':
        return adminColor;
      case 'teacher':
        return teacherColor;
      case 'student':
        return studentColor;
      case 'parent':
        return parentColor;
      default:
        return staffColor;
    }
  }
}
