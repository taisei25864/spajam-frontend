import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark();
    final bodyFont = GoogleFonts.mPlusRounded1c();
    final titleFont = GoogleFonts.notoSerifJp(fontWeight: FontWeight.w700);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF271D17),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD94A2C),
        background: const Color(0xFF271D17),
        primary: const Color(0xFFD94A2C),      // 朱
        secondary: const Color(0xFF26435F),    // 藍
        tertiary: const Color(0xFFD8B25C),     // 金
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: titleFont.copyWith(color: const Color(0xFFEFE9E2)),
        bodyMedium: bodyFont.copyWith(color: const Color(0xFFEDE6DE)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF33251E),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.78)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5A4438)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8B25C), width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD94A2C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: bodyFont.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ).merge(
          ButtonStyle(
            overlayColor: WidgetStateProperty.all(const Color(0xFFFF6A46).withOpacity(0.25)),
          ),
        ),
      ),
    );
  }
}