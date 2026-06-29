import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF5C9EE0);
  static const Color primaryDark = Color(0xFF1A3A5C);
  static const Color gold = Color(0xFFFFB300);
  static const Color goldDark = Color(0xFF4A3400);
  static const Color purple = Color(0xFFAB7FE0);
  static const Color purpleDark = Color(0xFF2D1F4A);
  static const Color surfaceDark = Color(0xFF0D1B2A);
  static const Color backgroundDark = Color(0xFF071018);
  static const Color cardDark = Color(0xFF122032);
  static const Color onSurface = Color(0xFFE8EDF5);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        primaryContainer: primaryDark,
        secondary: gold,
        secondaryContainer: goldDark,
        tertiary: purple,
        tertiaryContainer: purpleDark,
        surface: surfaceDark,
        onSurface: onSurface,
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E3A52), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return gold;
          return const Color(0xFF4A5568);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return goldDark;
          }
          return const Color(0xFF2D3748);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF122032),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A52)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A52)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8BAFC9)),
        hintStyle: const TextStyle(color: Color(0xFF4A6B85)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF122032),
        selectedColor: primaryBlue.withValues(alpha: 0.3),
        checkmarkColor: primaryBlue,
        labelStyle: const TextStyle(color: onSurface, fontSize: 13),
        side: const BorderSide(color: Color(0xFF1E3A52)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E3A52),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: onSurface,
        iconColor: Color(0xFF8BAFC9),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A3A5C),
        contentTextStyle: const TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
