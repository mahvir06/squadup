import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryTurquoise = Color(0xFF40E0D0);
  static const Color deepNavy = Color(0xFF1A1F25);
  static const Color oceanBlue = Color(0xFF006994);
  static const Color sandGold = Color(0xFFF7DBA7);
  static const Color coralAccent = Color(0xFFFF6B6B);
  
  // Functional Colors
  static const Color onlineColor = Color(0xFF4AE3B5);
  static const Color offlineColor = Color(0xFF9CA3AF);
  static const Color downToPlayColor = Color(0xFF4AE3B5);
  static const Color notDownToPlayColor = Color(0xFFFF6B6B);

  // Light theme colors
  static const Color _lightPrimaryColor = primaryTurquoise;
  static const Color _lightPrimaryVariantColor = oceanBlue;
  static const Color _lightSecondaryColor = coralAccent;
  static const Color _lightBackgroundColor = Color(0xFFF8FAFC);
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightErrorColor = Color(0xFFDC2626);
  static const Color _lightTextColor = Color(0xFF1A1F25);
  static const Color _lightSecondaryTextColor = Color(0xFF64748B);

  // Dark theme colors (OLED)
  static const Color _darkPrimaryColor = primaryTurquoise;
  static const Color _darkPrimaryVariantColor = Color(0xFF134E4A);
  static const Color _darkSecondaryColor = coralAccent;
  static const Color _darkBackgroundColor = Colors.black;
  static const Color _darkSurfaceColor = Color(0xFF1C1C1C);
  static const Color _darkCardColor = Color(0xFF242424);
  static const Color _darkErrorColor = Color(0xFFEF4444);
  static const Color _darkTextColor = Colors.white;
  static const Color _darkSecondaryTextColor = Color(0xFFADB5BD);

  static TextTheme _buildTextTheme(bool isDark) {
    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme();
    final primaryColor = isDark ? _darkTextColor : _lightTextColor;
    final secondaryColor = isDark ? _darkSecondaryTextColor : _lightSecondaryTextColor;
    
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: primaryColor),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: primaryColor),
      displaySmall: baseTextTheme.displaySmall?.copyWith(color: primaryColor),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: primaryColor),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: primaryColor),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: primaryColor),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: primaryColor),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: primaryColor),
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: primaryColor),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: primaryColor),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: primaryColor),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: secondaryColor),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: primaryColor),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: primaryColor),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: secondaryColor),
    );
  }

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _lightPrimaryColor,
      primaryContainer: _lightPrimaryVariantColor,
      secondary: _lightSecondaryColor,
      background: _lightBackgroundColor,
      surface: _lightSurfaceColor,
      error: _lightErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightTextColor,
      onBackground: _lightTextColor,
      onError: Colors.white,
    ),
    textTheme: _buildTextTheme(false),
    scaffoldBackgroundColor: _lightBackgroundColor,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: _lightBackgroundColor,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _lightTextColor,
      ),
      iconTheme: IconThemeData(color: _lightTextColor),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: deepNavy.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: _lightSurfaceColor,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: _lightSurfaceColor,
      textColor: _lightTextColor,
      iconColor: _lightTextColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: deepNavy.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: deepNavy.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _lightPrimaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: _lightSecondaryTextColor),
      hintStyle: TextStyle(color: _lightSecondaryTextColor),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimaryColor,
      primaryContainer: _darkPrimaryVariantColor,
      secondary: _darkSecondaryColor,
      background: _darkBackgroundColor,
      surface: _darkSurfaceColor,
      error: _darkErrorColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _darkTextColor,
      onBackground: _darkTextColor,
      onError: Colors.white,
    ),
    textTheme: _buildTextTheme(true),
    scaffoldBackgroundColor: _darkBackgroundColor,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: _darkBackgroundColor,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkTextColor,
      ),
      iconTheme: IconThemeData(color: _darkTextColor),
    ),
    cardTheme: CardTheme(
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: _darkCardColor,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: _darkCardColor,
      textColor: _darkTextColor,
      iconColor: _darkTextColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.black,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: _darkSecondaryTextColor),
      hintStyle: TextStyle(color: _darkSecondaryTextColor),
    ),
  );
} 