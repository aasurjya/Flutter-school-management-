import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_colors.dart';

/// Theme mode provider — system / light / dark, persisted by the calling layer.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Application theme — Apple-style calm system.
///
/// Design choices (Phase 0 of the UX overhaul):
/// - Platform-native fonts: SF on iOS, Roboto on Android (no GoogleFonts).
/// - Apple HIG typography scale (Large Title 34 → Caption 11), tight tracking.
/// - 10pt card radius (was 16), 12pt button radius. No shadows on cards.
/// - Single grayscale tint; semantic colors reserved for status.
class AppTheme {
  AppTheme._();

  // ---- Platform font selection ----
  // On iOS/macOS we use the system "San Francisco" family — Flutter resolves
  // it via the CupertinoFont fallback when fontFamily is null. To be explicit
  // and avoid GoogleFonts (which downloads at runtime), we hand Flutter the
  // platform default. On Android, null = Roboto; on iOS, null = SF.
  static String? get _fontFamily {
    if (kIsWeb) return null; // browser stack: system fallback
    if (Platform.isIOS || Platform.isMacOS) return '.SF Pro Text';
    return null; // Android / Linux / Windows: native stack
  }

  // Display variants on iOS use SF Pro Display for sizes >= 20pt.
  static String? get _displayFontFamily {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isMacOS) return '.SF Pro Display';
    return null;
  }

  // ============================================
  // LIGHT THEME
  // ============================================
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  // ============================================
  // DARK THEME
  // ============================================
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tint = isDark ? AppColors.tintDark : AppColors.tint;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.tint,
        brightness: brightness,
        primary: tint,
        secondary: tint,
        tertiary: tint,
        surface: isDark
            ? AppColors.systemBackgroundDark
            : AppColors.systemBackground,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: isDark
          ? AppColors.systemGroupedBackgroundDark
          : AppColors.systemGroupedBackground,
      textTheme: _buildTextTheme(brightness),
      appBarTheme: _buildAppBarTheme(brightness),
      cardTheme: _buildCardTheme(brightness),
      elevatedButtonTheme: _buildElevatedButtonTheme(brightness),
      outlinedButtonTheme: _buildOutlinedButtonTheme(brightness),
      textButtonTheme: _buildTextButtonTheme(brightness),
      filledButtonTheme: _buildFilledButtonTheme(brightness),
      inputDecorationTheme: _buildInputDecorationTheme(brightness),
      chipTheme: _buildChipTheme(brightness),
      bottomNavigationBarTheme: _buildBottomNavTheme(brightness),
      navigationBarTheme: _buildNavigationBarTheme(brightness),
      floatingActionButtonTheme: _buildFabTheme(brightness),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.separatorDark : AppColors.separator,
        thickness: 0.5, // Apple hairline — not the Material default 1pt.
        space: 0.5,
      ),
      snackBarTheme: _buildSnackBarTheme(brightness),
      bottomSheetTheme: _buildBottomSheetTheme(brightness),
      listTileTheme: _buildListTileTheme(brightness),
      splashFactory: NoSplash.splashFactory, // calmer touch feedback
      highlightColor: Colors.transparent,
    );
  }

  // ============================================
  // TYPOGRAPHY — Apple Human Interface scale
  //
  // Mapping (Material TextTheme slot → iOS HIG name):
  //   displayLarge   ⇄ largeTitle (34/41 w700)
  //   displayMedium  ⇄ title1     (28/34 w700)
  //   displaySmall   ⇄ title2     (22/28 w600)
  //   headlineLarge  ⇄ title2     (22/28 w600)
  //   headlineMedium ⇄ title3     (20/25 w600)
  //   headlineSmall  ⇄ headline   (17/22 w600)
  //   titleLarge     ⇄ headline   (17/22 w600)
  //   titleMedium    ⇄ callout    (16/21 w400) bumped to w600 for emphasis
  //   titleSmall     ⇄ subheadline(15/20 w600)
  //   bodyLarge      ⇄ body       (17/22 w400)
  //   bodyMedium     ⇄ callout    (16/21 w400)
  //   bodySmall      ⇄ footnote   (13/18 w400)
  //   labelLarge     ⇄ headline   (17/22 w600) — button text
  //   labelMedium    ⇄ subheadline(15/20 w600)
  //   labelSmall     ⇄ caption1   (12/16 w400)
  // ============================================
  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark ? AppColors.labelDark : AppColors.label;
    final secondary =
        brightness == Brightness.dark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel;

    TextStyle display(double size, FontWeight w, double ls, double h) => TextStyle(
          fontFamily: _displayFontFamily,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h / size,
          color: color,
        );

    TextStyle text(double size, FontWeight w, double ls, double h, {Color? c}) => TextStyle(
          fontFamily: _fontFamily,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h / size,
          color: c ?? color,
        );

    return TextTheme(
      // Large Title — only used on top of root scrollable screens.
      displayLarge:   display(34, FontWeight.w700, -0.4, 41),
      // Title 1
      displayMedium:  display(28, FontWeight.w700, -0.4, 34),
      // Title 2
      displaySmall:   display(22, FontWeight.w600, -0.3, 28),
      headlineLarge:  display(22, FontWeight.w600, -0.3, 28),
      // Title 3
      headlineMedium: display(20, FontWeight.w600, -0.3, 25),
      // Headline
      headlineSmall:  text(17, FontWeight.w600, -0.4, 22),
      titleLarge:     text(17, FontWeight.w600, -0.4, 22),
      // Callout (slot used for cell titles)
      titleMedium:    text(16, FontWeight.w600, -0.3, 21),
      // Subheadline
      titleSmall:     text(15, FontWeight.w600, -0.2, 20),
      // Body
      bodyLarge:      text(17, FontWeight.w400, -0.4, 22),
      // Callout
      bodyMedium:     text(16, FontWeight.w400, -0.3, 21),
      // Footnote
      bodySmall:      text(13, FontWeight.w400, -0.1, 18, c: secondary),
      // Button text — Apple uses headline weight on buttons.
      labelLarge:     text(17, FontWeight.w600, -0.4, 22),
      // Subheadline (chips, segmented)
      labelMedium:    text(15, FontWeight.w600, -0.2, 20),
      // Caption 1
      labelSmall:     text(12, FontWeight.w400, 0, 16, c: secondary),
    );
  }

  // ============================================
  // APP BAR — large title style, hairline bottom edge.
  // ============================================
  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: isDark ? AppColors.labelDark : AppColors.label,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      shape: Border(
        bottom: BorderSide(
          color: isDark ? AppColors.separatorDark : AppColors.separator,
          width: 0.5,
        ),
      ),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: isDark ? AppColors.labelDark : AppColors.label,
      ),
    );
  }

  // ============================================
  // CARD — solid grouped surface, hairline edge, no shadow.
  // ============================================
  static CardThemeData _buildCardTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CardThemeData(
      elevation: 0,
      color: isDark
          ? AppColors.secondaryGroupedBackgroundDark
          : AppColors.secondaryGroupedBackground,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      margin: EdgeInsets.zero,
    );
  }

  // ============================================
  // BUTTONS
  // ============================================
  static ElevatedButtonThemeData _buildElevatedButtonTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: isDark ? AppColors.tintDark : AppColors.tint,
        foregroundColor: isDark ? AppColors.label : Colors.white,
        minimumSize: const Size(44, 44), // Apple 44pt touch target
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        textStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? AppColors.tintDark : AppColors.tint,
        foregroundColor: isDark ? AppColors.label : Colors.white,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        textStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tint = isDark ? AppColors.tintDark : AppColors.tint;
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tint,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        side: BorderSide(
          color: isDark ? AppColors.separatorDark : AppColors.opaqueSeparator,
          width: 1,
        ),
        textStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.tintDark : AppColors.tint,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  // ============================================
  // INPUT — filled, hairline focus only.
  // ============================================
  static InputDecorationTheme _buildInputDecorationTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fill = isDark ? AppColors.inputFillDark : AppColors.inputFillLight;
    final tint = isDark ? AppColors.tintDark : AppColors.tint;

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: tint, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        color: isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel,
      ),
      hintStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        color: isDark ? AppColors.placeholderTextDark : AppColors.placeholderText,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: tint,
      ),
    );
  }

  // ============================================
  // CHIPS — capsule-style, low contrast.
  // ============================================
  static ChipThemeData _buildChipTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ChipThemeData(
      backgroundColor: isDark
          ? AppColors.tertiarySystemBackgroundDark
          : AppColors.secondarySystemBackground,
      selectedColor: isDark ? AppColors.tintDark : AppColors.tint,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      ),
      side: BorderSide.none,
    );
  }

  // ============================================
  // BOTTOM NAV (legacy Material widget)
  // ============================================
  static BottomNavigationBarThemeData _buildBottomNavTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tint = isDark ? AppColors.tintDark : AppColors.tint;
    return BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: isDark
          ? AppColors.secondarySystemBackgroundDark
          : AppColors.systemBackground,
      selectedItemColor: tint,
      unselectedItemColor: isDark ? AppColors.tertiaryLabelDark : AppColors.tertiaryLabel,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      showSelectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ============================================
  // NAVIGATION BAR (Material 3)
  // ============================================
  static NavigationBarThemeData _buildNavigationBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tint = isDark ? AppColors.tintDark : AppColors.tint;
    return NavigationBarThemeData(
      elevation: 0,
      height: 56,
      backgroundColor: isDark
          ? AppColors.secondarySystemBackgroundDark
          : AppColors.systemBackground,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: _fontFamily,
          fontSize: 10,
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          color: selected
              ? tint
              : (isDark ? AppColors.tertiaryLabelDark : AppColors.tertiaryLabel),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected
              ? tint
              : (isDark ? AppColors.tertiaryLabelDark : AppColors.tertiaryLabel),
        );
      }),
    );
  }

  // ============================================
  // FAB
  // ============================================
  static FloatingActionButtonThemeData _buildFabTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      backgroundColor: isDark ? AppColors.tintDark : AppColors.tint,
      foregroundColor: isDark ? AppColors.label : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }

  // ============================================
  // SNACKBAR — floating capsule, dark.
  // ============================================
  static SnackBarThemeData _buildSnackBarTheme(Brightness brightness) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.label, // pure black, like iOS toast
      contentTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      elevation: 0,
    );
  }

  // ============================================
  // BOTTOM SHEET — grouped surface, sheet radius.
  // ============================================
  static BottomSheetThemeData _buildBottomSheetTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return BottomSheetThemeData(
      backgroundColor: isDark
          ? AppColors.secondarySystemBackgroundDark
          : AppColors.systemBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      showDragHandle: true,
      dragHandleColor: brightness == Brightness.dark
          ? AppColors.tertiaryLabelDark
          : AppColors.tertiaryLabel,
    );
  }

  // ============================================
  // LIST TILE — Apple Settings-cell defaults.
  // ============================================
  static ListTileThemeData _buildListTileTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minVerticalPadding: 12,
      iconColor: isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        color: isDark ? AppColors.labelDark : AppColors.label,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel,
      ),
    );
  }
}
