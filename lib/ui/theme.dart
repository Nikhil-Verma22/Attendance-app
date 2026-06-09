import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Brand Colors (Charcoal Minimalist Theme)
  static Color backgroundStart = const Color(0xFF121212);
  static Color backgroundEnd = const Color(0xFF0A0A0A);
  
  static Color primary = const Color(0xFF9E9E9E);
  static Color primaryLight = const Color(0xFF424242);
  
  static Color success = const Color(0xFF81C784);
  static Color successLight = const Color(0xFF273B28);
  
  static Color warning = const Color(0xFFFFD54F);
  static Color warningLight = const Color(0xFF4D411C);
  
  static Color error = const Color(0xFFE57373);
  static Color errorLight = const Color(0xFF452626);

  static Color cardBg = const Color(0xFF212121);
  static Color textPrimary = const Color(0xFFF5F5F5);
  static Color textSecondary = const Color(0xFFBDBDBD);
  static Color neutralBorder = const Color(0xFF424242);

  static Future<void> saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_backgroundStart', backgroundStart.value);
    await prefs.setInt('theme_backgroundEnd', backgroundEnd.value);
    await prefs.setInt('theme_primary', primary.value);
    await prefs.setInt('theme_primaryLight', primaryLight.value);
    await prefs.setInt('theme_success', success.value);
    await prefs.setInt('theme_successLight', successLight.value);
    await prefs.setInt('theme_warning', warning.value);
    await prefs.setInt('theme_warningLight', warningLight.value);
    await prefs.setInt('theme_error', error.value);
    await prefs.setInt('theme_errorLight', errorLight.value);
    await prefs.setInt('theme_cardBg', cardBg.value);
    await prefs.setInt('theme_textPrimary', textPrimary.value);
    await prefs.setInt('theme_textSecondary', textSecondary.value);
    await prefs.setInt('theme_neutralBorder', neutralBorder.value);
  }

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('theme_primary')) {
      backgroundStart = Color(prefs.getInt('theme_backgroundStart') ?? 0xFF121212);
      backgroundEnd = Color(prefs.getInt('theme_backgroundEnd') ?? 0xFF0A0A0A);
      primary = Color(prefs.getInt('theme_primary') ?? 0xFF9E9E9E);
      primaryLight = Color(prefs.getInt('theme_primaryLight') ?? 0xFF424242);
      success = Color(prefs.getInt('theme_success') ?? 0xFF81C784);
      successLight = Color(prefs.getInt('theme_successLight') ?? 0xFF273B28);
      warning = Color(prefs.getInt('theme_warning') ?? 0xFFFFD54F);
      warningLight = Color(prefs.getInt('theme_warningLight') ?? 0xFF4D411C);
      error = Color(prefs.getInt('theme_error') ?? 0xFFE57373);
      errorLight = Color(prefs.getInt('theme_errorLight') ?? 0xFF452626);
      cardBg = Color(prefs.getInt('theme_cardBg') ?? 0xFF212121);
      textPrimary = Color(prefs.getInt('theme_textPrimary') ?? 0xFFF5F5F5);
      textSecondary = Color(prefs.getInt('theme_textSecondary') ?? 0xFFBDBDBD);
      neutralBorder = Color(prefs.getInt('theme_neutralBorder') ?? 0xFF424242);
    }
  }

  static Future<void> resetTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('theme_backgroundStart');
    await prefs.remove('theme_backgroundEnd');
    await prefs.remove('theme_primary');
    await prefs.remove('theme_primaryLight');
    await prefs.remove('theme_success');
    await prefs.remove('theme_successLight');
    await prefs.remove('theme_warning');
    await prefs.remove('theme_warningLight');
    await prefs.remove('theme_error');
    await prefs.remove('theme_errorLight');
    await prefs.remove('theme_cardBg');
    await prefs.remove('theme_textPrimary');
    await prefs.remove('theme_textSecondary');
    await prefs.remove('theme_neutralBorder');

    backgroundStart = const Color(0xFF121212);
    backgroundEnd = const Color(0xFF0A0A0A);
    primary = const Color(0xFF9E9E9E);
    primaryLight = const Color(0xFF424242);
    success = const Color(0xFF81C784);
    successLight = const Color(0xFF273B28);
    warning = const Color(0xFFFFD54F);
    warningLight = const Color(0xFF4D411C);
    error = const Color(0xFFE57373);
    errorLight = const Color(0xFF452626);
    cardBg = const Color(0xFF212121);
    textPrimary = const Color(0xFFF5F5F5);
    textSecondary = const Color(0xFFBDBDBD);
    neutralBorder = const Color(0xFF424242);
  }



  // Common UI Colors
  static Color white = Color(0xFFFFFFFF);
  static Color transparent = Color(0x00000000);
  static Color grey = Color(0xFF9E9E9E);
  static Color greyDark = Color(0xFF424242);
  static Color shadowColor = Color(0xFF000000);

  // Code Snippet / Terminal Colors
  static Color surfaceDark = const Color(0xFF1A1A1A);
  static Color surfaceDarker = Color(0xFF2D2D2D);
  static Color surfaceSidebar = Color(0xFF252526);
  static Color windowButtonRed = Color(0xFFFF5F56);
  static Color windowButtonYellow = Color(0xFFFFBD2E);
  static Color windowButtonGreen = Color(0xFF27C93F);
  static Color snippetKeyword = Color(0xFF4FC1FF);

  // Background Gradient Decoration
  static BoxDecoration backgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [backgroundStart, backgroundEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  // Soft Glassmorphic Card Shadow & Shape
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    double shadowOpacity = 0.05,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? cardBg,
      borderRadius: borderRadius ?? BorderRadius.circular(20.0),
      border: border ?? Border.all(color: neutralBorder.withOpacity(0.5), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: AppTheme.shadowColor.withOpacity(shadowOpacity),
          offset: const Offset(0, 10),
          blurRadius: 20.0,
          spreadRadius: -5.0,
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: primary,
        surface: cardBg,
        error: error,
      ),
      scaffoldBackgroundColor: AppTheme.transparent,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: textSecondary,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: neutralBorder.withOpacity(0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppTheme.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}