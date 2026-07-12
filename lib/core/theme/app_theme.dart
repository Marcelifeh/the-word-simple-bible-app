import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';

class AppTheme {
  // ── Palette tokens ──────────────────────────────────────────────────────────
  static const _bgDark = Color(0xFF090E1A);
  static const _surfaceDark = Color(0xFF111827);
  static const _primaryViolet = Color(0xFF8B5CF6); // HSL(258,89%,66%)
  static const _secondaryAmber = Color(0xFFF59E0B);
  static const _fontFallbacks = <String>[
    'NotoSans',
    'NotoSansSymbols2',
    'NotoColorEmoji',
    'Segoe UI Emoji',
    'Apple Color Emoji',
  ];

  // ── Glass helpers ────────────────────────────────────────────────────────────
  static BoxDecoration glassCard({Color? color, double radius = 20}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: (color ?? Colors.white).withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      );

  static BoxDecoration gradientCard(
          {required List<Color> colors, double radius = 20}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [
            colors.first.withValues(alpha: 0.35),
            colors.last.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colors.first.withValues(alpha: 0.25),
          width: 1,
        ),
      );

  // ── Themes ──────────────────────────────────────────────────────────────────
  static ThemeData light(AppState state) {
    final scheme = ColorScheme.fromSeed(
        seedColor: state.primarySeed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      fontFamilyFallback: _fontFallbacks,
      textTheme: _textTheme(Colors.black87),
      pageTransitionsTheme: _transitions,
    );
  }

  static ThemeData dark(AppState state) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primaryViolet,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _primaryViolet,
      secondary: _secondaryAmber,
      surface: _surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      fontFamilyFallback: _fontFallbacks,
      scaffoldBackgroundColor: _bgDark,
      textTheme: _textTheme(Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceDark,
        indicatorColor: _primaryViolet.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: 'Poppins',
            fontFamilyFallback: _fontFallbacks,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 0.5,
      ),
      pageTransitionsTheme: _transitions,
    );
  }

  static TextTheme _textTheme(Color base) => TextTheme(
        displayLarge: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: base),
        headlineLarge: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: base),
        headlineMedium: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: base),
        titleLarge: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: base),
        titleMedium: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: base),
        bodyLarge: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: base),
        bodyMedium: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: base.withValues(alpha: 0.75)),
        labelLarge: _textStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: base),
      );

  static TextStyle _textStyle({
    required String fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: _fontFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static const _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  );
}
