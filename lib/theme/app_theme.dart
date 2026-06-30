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
          if (states.contains(WidgetState.selected)) return goldDark;
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

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    const Color lPrimary = Color(0xFF2870C4);
    const Color lPrimaryContainer = Color(0xFFD5E8F5);
    const Color lOnSurface = Color(0xFF1A2A3C);
    const Color lScaffold = Color(0xFFF5F7FA);
    const Color lCard = Color(0xFFFFFFFF);

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: lPrimary,
        primaryContainer: lPrimaryContainer,
        secondary: gold,
        secondaryContainer: Color(0xFFFFF0CC),
        tertiary: Color(0xFF7B5FB0),
        tertiaryContainer: Color(0xFFEEE5FF),
        surface: Color(0xFFF5F7FA),
        onSurface: lOnSurface,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lScaffold,
      cardTheme: CardThemeData(
        color: lCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDDE5EE), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lPrimary;
          return const Color(0xFFB0BEC5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lPrimaryContainer;
          return const Color(0xFFE0E0E0);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F5FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE5EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE5EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF5A80A0)),
        hintStyle: const TextStyle(color: Color(0xFFAABBCC)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lPrimary,
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
        backgroundColor: const Color(0xFFF0F5FA),
        selectedColor: lPrimary.withValues(alpha: 0.15),
        checkmarkColor: lPrimary,
        labelStyle: const TextStyle(color: lOnSurface, fontSize: 13),
        side: const BorderSide(color: Color(0xFFDDE5EE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDDE5EE),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: lOnSurface,
        iconColor: Color(0xFF5A80A0),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Couleurs adaptatives selon le mode clair/sombre.
extension AppThemeX on ThemeData {
  bool get _isDark => brightness == Brightness.dark;

  Color get appCard => _isDark ? const Color(0xFF122032) : Colors.white;
  Color get appDeep => _isDark ? const Color(0xFF0D1B2A) : const Color(0xFFEEF3FA);
  Color get appChipBg => _isDark ? const Color(0xFF122032) : const Color(0xFFF0F5FA);
  Color get appBorder => _isDark ? const Color(0xFF1E3A52) : const Color(0xFFDDE5EE);
  Color get appSubtle => _isDark ? const Color(0xFF4A6B85) : const Color(0xFF7A98B0);
  Color get appMid => _isDark ? const Color(0xFF8BAFC9) : const Color(0xFF5A80A0);
  Color get appText => _isDark ? const Color(0xFFE8EDF5) : const Color(0xFF1A2A3C);
  Color get appPrimaryContainer =>
      _isDark ? const Color(0xFF1A3A5C) : const Color(0xFFD5E8F5);
  Color get appPastZman => _isDark ? const Color(0xFF2D4A62) : const Color(0xFFBBCCDD);
  List<Color> get appHeaderGradient => _isDark
      ? [const Color(0xFF0D1B2A), const Color(0xFF122032)]
      : [const Color(0xFFD4E8F7), const Color(0xFFE8F3FC)];
}
