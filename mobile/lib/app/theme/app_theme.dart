import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const Color seed = AppColors.mistBlue;
    final TextTheme baseTextTheme =
        GoogleFonts.notoSansScTextTheme(ThemeData(brightness: Brightness.light).textTheme);

    final TextTheme textTheme = baseTextTheme.copyWith(
      headlineLarge: GoogleFonts.notoSerifSc(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.16,
        color: AppColors.ink,
      ),
      headlineMedium: GoogleFonts.notoSerifSc(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.18,
        color: AppColors.ink,
      ),
      headlineSmall: GoogleFonts.notoSerifSc(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.ink,
      ),
      titleLarge: GoogleFonts.notoSansSc(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.28,
        color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.notoSansSc(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.notoSansSc(
        fontSize: 16,
        height: 1.55,
        color: AppColors.ink,
      ),
      bodyMedium: GoogleFonts.notoSansSc(
        fontSize: 14,
        height: 1.55,
        color: AppColors.ink,
      ),
      bodySmall: GoogleFonts.notoSansSc(
        fontSize: 12,
        height: 1.4,
        letterSpacing: 0.1,
        color: AppColors.subInk,
      ),
      labelLarge: GoogleFonts.notoSansSc(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: AppColors.ink,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        primary: AppColors.mistBlue,
        secondary: AppColors.lavender,
        surface: AppColors.softCream,
      ),
      scaffoldBackgroundColor: AppColors.skyBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansSc(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.78),
        selectedColor: AppColors.lavender.withValues(alpha: 0.36),
        labelStyle: GoogleFonts.notoSansSc(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.72),
        hintStyle: GoogleFonts.notoSansSc(
          fontSize: 14,
          height: 1.45,
          color: AppColors.subInk.withValues(alpha: 0.92),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class AppColors {
  static const Color skyBackground = Color(0xFFF4F8FF);
  static const Color softCream = Color(0xFFFDF8EF);
  static const Color mistBlue = Color(0xFFAEC5E6);
  static const Color lavender = Color(0xFFC8B8E0);
  static const Color peachGlow = Color(0xFFFEDFD4);
  static const Color calmGreen = Color(0xFFCFE8DE);
  static const Color ink = Color(0xFF334155);
  static const Color subInk = Color(0xFF64748B);
  static const Color gentleRed = Color(0xFFF2C4C4);
  static const Color sun = Color(0xFFFFE6B0);
}

class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadii {
  static const double card = 24;
  static const double chip = 18;
  static const double input = 18;
  static const double button = 20;
}
