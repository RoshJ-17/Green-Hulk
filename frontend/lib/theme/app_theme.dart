import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colours ──
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep green
  static const Color accentGreen = Color(0xFF8BC34A);   // Lime accent
  static const Color lightGreen = Color(0xFFA5D6A7);    // Soft highlight
  static const Color earthBrown = Color(0xFF6D4C41);     // Soil brown
  static const Color cream = Color(0xFFF9FBF2);          // Soft off-white bg
  static const Color white = Color(0xFFFFFFFF);
  static const Color organicGreen = Color(0xFF66BB6A);

  // ── Main Theme ──
  static ThemeData get highContrastTheme {
    final poppins = GoogleFonts.poppinsTextTheme();
    final nunito = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      // Core colours
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: primaryGreen,
      ),

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: white, size: 28),
      ),

      // Text Theme — Poppins for headings, Nunito for body
      textTheme: TextTheme(
        headlineLarge: poppins.headlineLarge!.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
        headlineMedium: poppins.headlineMedium!.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
        headlineSmall: poppins.headlineSmall!.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
        bodyLarge: nunito.bodyLarge!.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryGreen,
        ),
        bodyMedium: nunito.bodyMedium!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryGreen,
        ),
        labelLarge: poppins.labelLarge!.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),

      // Buttons — pill-shaped (StadiumBorder)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: white,
          minimumSize: const Size(120, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          elevation: 3,
        ),
      ),

      // Cards — rounded with soft shadows
      cardTheme: CardThemeData(
        color: white,
        elevation: 3,
        shadowColor: primaryGreen.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Icons
      iconTheme: const IconThemeData(size: 32, color: accentGreen),
    );
  }

  // Spacing constants
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Touch target sizes
  static const double minTouchTarget = 54.0;
  static const double iconSize = 32.0;
  static const double iconSizeLarge = 48.0;
}