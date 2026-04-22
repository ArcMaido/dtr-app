import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color pine = Color(0xFF183A66);
  static const Color moss = Color(0xFF2F6C9D);
  static const Color clay = Color(0xFF0FA3B1);
  static const Color sand = Color(0xFFF6FAFF);
  static const Color mist = Color(0xFFE9F4FF);
  static const Color ink = Color(0xFF1A2B40);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: pine,
      primary: pine,
      secondary: clay,
      tertiary: moss,
      surface: sand,
      onSurface: ink,
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme().copyWith(
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        color: ink,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        color: pine,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: sand,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.85),
        foregroundColor: pine,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white.withOpacity(0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1A183A66)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: moss,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: moss, width: 1.2),
          foregroundColor: moss,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: pine,
        contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.96),
        indicatorColor: mist,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? pine : const Color(0xFF6C819B),
            fontSize: 12,
          );
        }),
      ),
    );
  }
}
