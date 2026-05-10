import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4155b5);
  static const Color primaryDarkColor = Color(0xFF2a3a8c);
  static const Color primaryLightColor = Color(0xFF7d97f4);
  static const Color accentColor = Color(0xFFf97316);
  
  // Light theme colors
  static const Color lightTextColor = Color(0xFF334155);
  static const Color lightTextLightColor = Color(0xFF64748b);
  static const Color lightBgColor = Color(0xFFf8fafc);
  static const Color lightCardBgColor = Color(0xFFffffff);
  static const Color lightBorderColor = Color(0xFFe2e8f0);
  
  // Dark theme colors
  static const Color darkTextColor = Color(0xFFe2e8f0);
  static const Color darkTextLightColor = Color(0xFF94a3b8);
  static const Color darkBgColor = Color(0xFF1e293b);
  static const Color darkHeaderColor = Color(0xFF12193F);
  static const Color darkCardBgColor = Color(0xFF334155);
  static const Color darkBorderColor = Color(0xFF475569);

  static final _baseTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.w300, letterSpacing: -1.5),
    displayMedium: TextStyle(fontSize: 60, fontWeight: FontWeight.w300, letterSpacing: -0.5),
    displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    headlineMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w400),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0.15),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBgColor,
    fontFamily: 'Sarabun',
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      color: lightCardBgColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: lightTextColor,
      displayColor: lightTextColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: primaryLightColor,
      labelStyle: TextStyle(color: Colors.white),
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      surface: lightCardBgColor,
      onSurface: lightTextColor,
      background: lightBgColor,
      onBackground: lightTextColor,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBgColor,
    fontFamily: 'Sarabun',
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDarkColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      color: darkCardBgColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: darkTextColor,
      displayColor: darkTextColor,
    ).copyWith(
      titleLarge: const TextStyle(color: Colors.white), // กำหนดสีขาวสำหรับ title ใน dark mode
      titleMedium: const TextStyle(color: Colors.white),
      titleSmall: const TextStyle(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLightColor,
        side: const BorderSide(color: primaryLightColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconTheme: const IconThemeData(
      color: primaryLightColor,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: primaryColor,
      labelStyle: TextStyle(color: Colors.white),
    ),
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      surface: darkCardBgColor,
      onSurface: darkTextColor,
      background: darkBgColor,
      onBackground: darkTextColor,
    ),
  );
}