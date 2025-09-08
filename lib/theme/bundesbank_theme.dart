import 'package:flutter/material.dart';

class BundesbankColors {
  static const Color bundesbankBlue = Color(0xFF004B87);
  static const Color bundesbankGold = Color(0xFFF2A900);
  static const Color textBlack = Color(0xFF000000);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF757575);
  
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
}

class BundesbankTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: BundesbankColors.bundesbankBlue,
        secondary: BundesbankColors.bundesbankGold,
        surface: BundesbankColors.backgroundWhite,
        error: BundesbankColors.errorRed,
        onPrimary: BundesbankColors.backgroundWhite,
        onSecondary: BundesbankColors.textBlack,
        onSurface: BundesbankColors.textBlack,
        onError: BundesbankColors.backgroundWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BundesbankColors.bundesbankBlue,
        foregroundColor: BundesbankColors.backgroundWhite,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BundesbankColors.bundesbankBlue,
          foregroundColor: BundesbankColors.backgroundWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BundesbankColors.mediumGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BundesbankColors.bundesbankBlue, width: 2),
        ),
      ),
    );
  }
}