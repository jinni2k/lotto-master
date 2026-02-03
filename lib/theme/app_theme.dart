import 'package:flutter/material.dart';

class AppTheme {
  static const Color _gold = Color(0xFFD8B24C);
  static const Color _goldSoft = Color(0xFFF4D98C);
  static const Color _goldDeep = Color(0xFF8C6A1A);
  static const Color _ink = Color(0xFF0B0A0D);
  static const Color _inkSoft = Color(0xFF151318);
  static const Color _ivory = Color(0xFFF3EBDD);

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: _gold,
      onPrimary: _ink,
      secondary: _goldSoft,
      onSecondary: _ink,
      surface: isDark ? const Color(0xFF141219) : const Color(0xFFF6F0E4),
      onSurface: isDark ? const Color(0xFFF5EEE2) : const Color(0xFF221E18),
      background: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF7F2EA),
      onBackground: isDark ? const Color(0xFFF5EEE2) : const Color(0xFF221E18),
      error: const Color(0xFFEF5350),
      onError: Colors.white,
      primaryContainer: isDark ? const Color(0xFF3A2C12) : const Color(0xFFFFE7B3),
      onPrimaryContainer: isDark ? _goldSoft : _ink,
      secondaryContainer: isDark ? const Color(0xFF2B2010) : const Color(0xFFFFF2D2),
      onSecondaryContainer: isDark ? _goldSoft : _ink,
      outline: isDark ? const Color(0xFF3A3226) : const Color(0xFFE2D4BF),
      outlineVariant: isDark ? const Color(0xFF2A251C) : const Color(0xFFEADFCC),
    );

    final baseTextTheme = Typography.material2021().white;
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        height: 1.4,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        height: 1.35,
      ),
    ).apply(
      fontFamily: 'PlayfairDisplay',
      fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          letterSpacing: 0.6,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.92),
        indicatorColor: colorScheme.primaryContainer.withOpacity(0.7),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colorScheme.onSurface),
        ),
      ),
      cardTheme: CardTheme(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
          shadowColor: WidgetStatePropertyAll(_goldDeep.withOpacity(0.45)),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return 2;
            }
            if (states.contains(WidgetState.hovered)) {
              return 10;
            }
            return 8;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onPrimary.withOpacity(0.15);
            }
            return null;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.titleMedium),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.18);
            }
            return null;
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
          textStyle: WidgetStatePropertyAll(textTheme.titleSmall),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.12);
            }
            return null;
          }),
          foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.primary.withOpacity(0.6)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.5),
        thickness: 1,
      ),
    );
  }
}
