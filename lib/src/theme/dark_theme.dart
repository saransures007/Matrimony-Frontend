import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData getDarkTheme() {
  // 🎨 Brand Colors
  const primary = Color(0xFFC2185B); // Deep Rose
  const secondary = Color(0xFFD4AF37); // Gold

  const background = Color(0xFF121212);
  const surface = Color(0xFF1C1C1E);

  const textPrimary = Colors.white;
  const textSecondary = Color(0xFFB0B0B0);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    primaryColor: primary,

    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,

      secondary: secondary,
      onSecondary: Colors.black,

      surface: surface,
      onSurface: textPrimary,

      error: Color(0xFFE53935),
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: background,
    cardColor: surface,
    dividerColor: const Color(0xFF2C2C2E),

    // 📝 Typography (iOS-like)
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),

        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 13, color: textSecondary),
      ),
    ),

    // 🎛️ AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),

    // 🔘 Elevated Button (Premium feel)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ⚪ Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondary,
        side: const BorderSide(color: secondary, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),

    // 🔘 Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // 📥 Input Fields (iOS dark style)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: secondary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
      ),
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFF8E8E93),
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.poppins(
        color: textSecondary,
        fontSize: 14,
      ),
    ),

    // 🃏 Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      surfaceTintColor: Colors.transparent,
    ),

    // 👇 Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // 🎚️ TabBar
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: textSecondary,
      indicatorColor: primary,
      labelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
      ),
    ),

    // 🏷️ Chips
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2C2C2E),
      disabledColor: const Color(0xFF3A3A3C),
      selectedColor: primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: textPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // 🌀 Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      circularTrackColor: Colors.transparent,
    ),
  );
}