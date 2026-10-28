import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF1BBC9B); // PLAS Teal
  static const Color primaryDark = Color(0xFF148F77);
  static const Color darkBg = Color(0xFF1E212D);
  static const Color codeBg = Color(0xFF282C34);
  static const Color topButtonColor = Color(0xFF28A745); // Bootstrap btn-success

  // Status colors
  static const Color statusCompletedBg = Color(0xFFD4EDDA);
  static const Color statusCompletedText = Color(0xFF155724);
  static const Color statusCompletedBorder = Color(0xFFC3E6CB);

  static const Color statusTriedBg = Color(0xFFFFF3CD);
  static const Color statusTriedText = Color(0xFF856404);
  static const Color statusTriedBorder = Color(0xFFFFEEBA);

  static const Color statusNotAttemptedBg = Color(0xFFF1F3F5);
  static const Color statusNotAttemptedText = Color(0xFF495057);

  // Scoring input colors
  static const Color inputCorrectBg = Color(0xFFE8F5E9);
  static const Color inputCorrectBorder = Color(0xFF4CAF50);
  static const Color inputIncorrectBg = Color(0xFFFFEBEE); // Pinkish red
  static const Color inputIncorrectBorder = Color(0xFFEF5350);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: const Color(0xFF17A2B8),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCED4DA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCED4DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
