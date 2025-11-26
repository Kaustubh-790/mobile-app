import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Beige Palette
  static const Color beige4 = Color(0xFFF9F5F1);
  static const Color beige10 = Color(0xFFEFE7E1);
  static const Color beige50 = Color(0xFFF7EFE5);
  static const Color beige100 = Color(0xFFF0E3D4);
  static const Color beige200 = Color(0xFFE7D8C4);
  static const Color beige210 = Color(0xFFE7D8C8);
  static const Color beige250 = Color(0xFFC09C81);
  static const Color beigeDefault = Color(0xFFE7D8C8); // Main background
  static const Color beige400 = Color(0xFFBE9C7E);
  static const Color beige450 = Color(0xFFB58B5E);
  static const Color beige500 = Color(0xFFC99B78);

  // Sand Palette
  static const Color sand10 = Color(0xFFF3EEE7);
  static const Color sand40 = Color(0xFFFAF8F6);
  static const Color sand50 = Color(0xFFF5ECE3);
  static const Color sand100 = Color(0xFFEADDCF);
  static const Color sand200 = Color(0xFFE0CDB8);

  // Brown Palette
  static const Color brown50 = Color(0xFFEDE9E7);
  static const Color brown100 = Color(0xFFCFC4BD);
  static const Color brown200 = Color(0xFFA8958A);
  static const Color brown300 = Color(0xFF8B766C);
  static const Color brown350 = Color(0xFF4A392C);
  static const Color brown400 = Color(0xFF5F4B41);
  static const Color brown500 = Color(0xFF2E1F1B); // Main text
  static const Color brown600 = Color(0xFF2E1E18);
  static const Color brown700 = Color(0xFF1E120D);

  // Primary Colors
  static const Color primaryLight = Color(0xFFD9C9B9);
  static const Color primaryDefault = Color(0xFF2E1F1B); // Dark brown CTA
  static const Color primaryDark = Color(0xFF2B1A14);

  // Accents
  static const Color clay = Color(0xFFE7DCCC);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDefault,
      scaffoldBackgroundColor: beigeDefault,
      
      colorScheme: const ColorScheme.light(
        primary: primaryDefault,
        secondary: clay,
        surface: sand40, // Card background default
        background: beigeDefault,
        error: error,
        onPrimary: beige4, // Text on primary button
        onSecondary: brown500,
        onSurface: brown500,
        onBackground: brown500,
        onError: Colors.white,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.juliusSansOne(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: brown500,
        ),
        displayMedium: GoogleFonts.juliusSansOne(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: brown500,
        ),
        displaySmall: GoogleFonts.juliusSansOne(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: brown500,
        ),
        headlineMedium: GoogleFonts.juliusSansOne(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: brown500,
        ),
        headlineSmall: GoogleFonts.juliusSansOne(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: brown500,
        ),
        titleLarge: GoogleFonts.exo2(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: brown500,
        ),
        bodyLarge: GoogleFonts.exo2(
          fontSize: 16,
          color: brown500,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.exo2(
          fontSize: 14,
          color: brown500, // Was lightTextSecondary
          height: 1.5,
        ),
        labelLarge: GoogleFonts.exo2(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: beige4,
        ),
      ),

      cardTheme: CardThemeData(
        color: sand40,
        elevation: 0, // Flat or soft shadow as per design
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // 1.5rem = 24px
        ),
        margin: const EdgeInsets.all(8),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: beigeDefault,
        foregroundColor: brown500,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.juliusSansOne(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: brown500,
        ),
        iconTheme: const IconThemeData(color: brown500),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sand50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // 1rem
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryDefault, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.exo2(
          color: brown200,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDefault,
          foregroundColor: beige4,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.exo2(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brown500,
          textStyle: GoogleFonts.exo2(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brown500,
          side: const BorderSide(color: beige10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.exo2(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Keeping Dark Theme as a fallback, but mapping it to the same palette or a dark variant if needed.
  // For now, I'll map it to a "Dark Mode" version of the Brown/Beige palette if possible, 
  // or just keep it consistent with the Light Theme since the design is very specific about colors.
  // The user didn't specify a dark mode, so I will make the dark theme use the same values 
  // or slightly adjusted ones to ensure it doesn't break if the system is in dark mode.
  // Actually, let's just use the same theme for now to enforce the design.
  
  static ThemeData get darkTheme => lightTheme; 
}
