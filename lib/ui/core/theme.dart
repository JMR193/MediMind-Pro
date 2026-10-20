import 'package:flutter/material.dart';

class MediMindTheme {
  static const Color primaryBlue = Color(0xFF22593E); // Calming Healthcare Primary Forest Green
  static const Color accentTeal = Color(0xFF52B788);  // Fresh Mint Accent
  static const Color eyeDropPurple = Color(0xFF7C3AED);
  static const Color warningOrange = Color(0xFFD97706);
  static const Color alertRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF2D6A4F);

  // Modern Calming Healthcare 2.0 Palette
  static const Color calmingGreen = Color(0xFF22593E);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color mintAccent = Color(0xFF52B788);
  static const Color glowingLime = Color(0xFF74C69D);
  static const Color paleSage = Color(0xFFD8F3DC);
  static const Color sageBackground = Color(0xFFF4F9F5);
  static const Color cardSurface = Colors.white;

  static ThemeData lightThemeWith(ColorScheme? dynamicColorScheme) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: calmingGreen,
          brightness: Brightness.light,
          primary: calmingGreen,
          secondary: mintAccent,
          tertiary: glowingLime,
          surface: sageBackground,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: sageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: sageBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF1B4332)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1B4332),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData darkThemeWith(ColorScheme? dynamicColorScheme) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.dark,
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFF2DD4BF),
          tertiary: const Color(0xFFA78BFA),
          surface: const Color(0xFF0F172A),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF020617),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData lightTheme = lightThemeWith(null);
  static ThemeData darkTheme = darkThemeWith(null);
}
