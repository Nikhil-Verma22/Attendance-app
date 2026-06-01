import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color backgroundStart = Color(0xFF0D144A);
  static const Color backgroundEnd = Color(0xFF060A26);
  
  static const Color primary = Color(0xFF3843E5);
  static const Color primaryLight = Color(0xFF1B2361);
  
  static const Color success = Color(0xFF23D05C);
  static const Color successLight = Color(0xFF0E3D22);
  
  static const Color warning = Color(0xFFFF9F2E);
  static const Color warningLight = Color(0xFF4A3114);
  
  static const Color error = Color(0xFFFF4858);
  static const Color errorLight = Color(0xFF4A161D);

  static const Color cardBg = Color(0xFF161E5B);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A8D9);
  static const Color neutralBorder = Color(0xFF283287);

  // Common UI Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);
  static const Color shadowColor = Color(0xFF000000);

  // Code Snippet / Terminal Colors
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDarker = Color(0xFF2D2D2D);
  static const Color surfaceSidebar = Color(0xFF252526);
  static const Color windowButtonRed = Color(0xFFFF5F56);
  static const Color windowButtonYellow = Color(0xFFFFBD2E);
  static const Color windowButtonGreen = Color(0xFF27C93F);
  static const Color snippetKeyword = Color(0xFF4FC1FF);

  // Background Gradient Decoration
  static BoxDecoration backgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [backgroundStart, backgroundEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  // Soft Glassmorphic Card Shadow & Shape
  static BoxDecoration cardDecoration({
    Color color = cardBg,
    BorderRadius? borderRadius,
    double shadowOpacity = 0.05,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
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
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primary,
        surface: cardBg,
        error: error,
      ),
      scaffoldBackgroundColor: AppTheme.transparent,
      textTheme: const TextTheme(
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
