import 'package:flutter/material.dart';

class AppTheme {
  // Agricultural theme colors - proper farming app colors!
  static const Color primaryGreen = Color(0xFF2D5016); // Deep forest green
  static const Color accentGreen = Color(0xFF4A7C2C); // Leaf green
  static const Color lightGreen = Color(0xFF7CB342); // Fresh plant green
  static const Color earthBrown = Color(0xFF6D4C41); // Soil brown
  static const Color cream = Color(0xFFFFF8E1); // Light cream background
  static const Color white = Color(0xFFFFFFFF);
  static const Color organicGreen = Color(0xFF66BB6A); // For organic badges
  
  // High Contrast Theme - Task 10 (Agricultural version)
  static ThemeData get highContrastTheme {
    return ThemeData(
      // Core colors
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: white,
        // background: cream, // Deprecated
        onPrimary: white,
        onSecondary: white,
        onSurface: primaryGreen,
        // onBackground: primaryGreen, // Deprecated
      ),
      
      // Native Page Transitions (Swipe Back support)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: white,
          size: 28,
        ),
      ),
      
      // Text Theme - Task 2: Readable fonts
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryGreen,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryGreen,
        ),
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),
      
      // Button Theme - Task 3: Properly sized buttons (not crazy big!)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: white,
          minimumSize: const Size(120, 54), // Good size for tapping
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          elevation: 3,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shadowColor: primaryGreen.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightGreen.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        size: 32,
        color: accentGreen,
      ),
    );
  }
  
  // Spacing constants
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // Touch target sizes
  static const double minTouchTarget = 54.0; // Reduced from 70
  static const double iconSize = 32.0; // Reduced from 48
  static const double iconSizeLarge = 48.0; // Reduced from 64
}