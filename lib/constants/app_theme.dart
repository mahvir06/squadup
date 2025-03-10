import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light theme colors
  static const Color _lightPrimaryColor = Color(0xFF6200EE);
  static const Color _lightPrimaryVariantColor = Color(0xFF3700B3);
  static const Color _lightSecondaryColor = Color(0xFF03DAC6);
  static const Color _lightSecondaryVariantColor = Color(0xFF018786);
  static const Color _lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightErrorColor = Color(0xFFB00020);
  static const Color _lightOnPrimaryColor = Colors.white;
  static const Color _lightOnSecondaryColor = Colors.black;
  static const Color _lightOnBackgroundColor = Colors.black;
  static const Color _lightOnSurfaceColor = Colors.black;
  static const Color _lightOnErrorColor = Colors.white;

  // Dark theme colors
  static const Color _darkPrimaryColor = Color(0xFFBB86FC);
  static const Color _darkPrimaryVariantColor = Color(0xFF3700B3);
  static const Color _darkSecondaryColor = Color(0xFF03DAC6);
  static const Color _darkSecondaryVariantColor = Color(0xFF03DAC6);
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color _darkErrorColor = Color(0xFFCF6679);
  static const Color _darkOnPrimaryColor = Colors.black;
  static const Color _darkOnSecondaryColor = Colors.black;
  static const Color _darkOnBackgroundColor = Colors.white;
  static const Color _darkOnSurfaceColor = Colors.white;
  static const Color _darkOnErrorColor = Colors.black;

  // Custom colors for our app
  static const Color onlineColor = Color(0xFF4CAF50);
  static const Color offlineColor = Color(0xFFBDBDBD);
  static const Color downToPlayColor = Colors.green;
  static const Color notDownToPlayColor = Color(0xFFE57373);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
  );
} 