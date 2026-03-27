import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF002B5C); // Navy Blue
  static const Color accentGold = Color(0xFFD4AF37); // School Gold
  static const Color backgroundLight = Color(0xFFF5F5F5); // Light Gray
  static const Color surfaceWhite = Colors.white;

  static ThemeData theme({
    required bool isDarkMode,
    required AccentColorType accentColorType,
  }) {
    final Color accentColor = accentColorType == AccentColorType.yellow
        ? accentGold
        : Colors.lightBlueAccent;

    final Color bgColor = isDarkMode ? const Color(0xFF0F1115) : backgroundLight;
    final Color surfaceColor = isDarkMode ? const Color(0xFF1A1F26) : surfaceWhite;
    final Color textColor = isDarkMode ? Colors.white : primaryBlue;
    final Color subTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: isDarkMode ? (accentColorType == AccentColorType.yellow ? Colors.amber[200]! : Colors.blue[300]!) : primaryBlue,
        secondary: accentColor,
        surface: surfaceColor,
        background: bgColor,
      ),
      cardColor: surfaceColor,
      canvasColor: isDarkMode ? const Color(0xFF151921) : Colors.white,
      dividerColor: isDarkMode ? Colors.white10 : Colors.black12,
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
          shadowColor: accentColor.withOpacity(0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: isDarkMode ? Colors.white12 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: TextStyle(color: textColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: subTextColor),
      ),
    );
  }

  // Keep original lightTheme mapping for safety/legacy
  static ThemeData get lightTheme => theme(isDarkMode: false, accentColorType: AccentColorType.yellow);
}
