import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFE94B3C); // Vibrant Food Red
  static const Color neonGreen = Color(0xFFA7F432); // Neon Green/Yellow from screenshots
  static const Color secondaryColor = Color(0xFF1A1A1A); // Deeper Dark Gray
  static const Color backgroundDark = Color(0xFF121212);
  static const Color nonVegRed = Color(0xFFDB545A);
  static const Color vegGreen = Color(0xFF87D58B);

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: neonGreen,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 48,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; // Temporary redirect
}
