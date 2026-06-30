import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceAlt = Color(0xFF22263A);
  static const Color accent = Color(0xFF3D9BFF); // eBay-adjacent blue
  static const Color accentWarm = Color(0xFFFFAA00); // bid/price highlight
  static const Color textPrimary = Color(0xFFEEF0F6);
  static const Color textMuted = Color(0xFF7A7F96);
  static const Color danger = Color(0xFFFF4D6A); // ending soon
  static const Color success = Color(0xFF28C784);
  static const Color divider = Color(0xFF2A2D3E);

  // ── Typography ────────────────────────────────────────────────────────────
  static const String fontFamily = 'Roboto'; // system font, zero download

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accentWarm,
      surface: surface,
      error: danger,
    ),
    textTheme: const TextTheme(
      // Table headers
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: textMuted,
      ),
      // Cell data
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      // Price
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: accentWarm,
      ),
      // Countdown
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    ),
    dividerColor: divider,
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    iconTheme: const IconThemeData(color: textMuted, size: 16),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceAlt,
      modalBackgroundColor: surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent.withValues(alpha: 0.2),
      side: const BorderSide(color: divider),
      labelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        color: textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surfaceAlt,
      contentTextStyle: TextStyle(color: textPrimary, fontFamily: fontFamily),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
  );
}
