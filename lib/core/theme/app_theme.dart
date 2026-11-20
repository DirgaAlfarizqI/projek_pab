import 'package:flutter/material.dart';

class AppTheme {
  // Palet Warna Wajib Master Prompt Final (Simple But Modern)
  static const Color primaryGreen = Color(0xFF287A4B); // Primary Green: #287A4B
  static const Color darkGreen = Color(0xFF174D35); // Dark Green: #174D35
  static const Color lightGreen = Color(0xFFE5F0E6); // Light Green: #E5F0E6
  static const Color cornYellow = Color(0xFFF3C94F); // Corn Yellow: #F3C94F
  static const Color creamBackground = Color(0xFFF8F7EF); // Cream: #F8F7EF
  static const Color surfaceWhite = Color(0xFFFFFFFF); // White: #FFFFFF

  // Alias kompatibilitas dengan komponen yang sudah ada
  static const Color primaryDarkGreen = darkGreen;
  static const Color deepForestGreen = darkGreen;
  static const Color leafGreen = primaryGreen;
  static const Color softMintGreen = lightGreen;
  static const Color lightLeafGreen = lightGreen;
  static const Color cornGold = Color(0xFFD9A628);
  static const Color cornYellowLight = Color(0xFFFCF5DC);

  // Warna Teks, Border, dan Status Konsisten
  static const Color textPrimary = Color(0xFF14241B);
  static const Color textSecondary = Color(0xFF5C6F63);
  static const Color borderColor = Color(0xFFE4E7E0);
  static const Color dangerRed = Color(0xFFD93829);
  static const Color dangerLight = Color(0xFFFDECEB);
  static const Color salmonLogout = Color(0xFFD94A38);
  static const Color infoBlue = Color(0xFF1E6FB8);
  static const Color infoLight = Color(0xFFE7F1FA);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      onPrimary: surfaceWhite,
      secondary: cornYellow,
      onSecondary: textPrimary,
      tertiary: darkGreen,
      surface: surfaceWhite,
      onSurface: textPrimary,
      error: dangerRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: creamBackground,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: surfaceWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkGreen,
          backgroundColor: surfaceWhite,
          side: const BorderSide(color: borderColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: Color(0xFF98A69D), fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 1.3),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        elevation: 4,
        shadowColor: Colors.black12,
        indicatorColor: lightGreen,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkGreen,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkGreen, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 22);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: surfaceWhite,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
    );
  }
}
