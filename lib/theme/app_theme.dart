import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual de Tetrapoda, tomada del portal web (portal.h).
///
/// Paleta de colores y tipografías replicadas para mantener coherencia
/// entre la app y el portal.
class AppColors {
  AppColors._();

  /// Tinta principal (texto / fondos oscuros).
  static const Color ink = Color(0xFF1a1a18);

  /// Fondo claro tipo papel.
  static const Color paper = Color(0xFFf4f1ea);

  /// Verde salvia (acento secundario).
  static const Color sage = Color(0xFF6b7c6e);

  /// Verde salvia claro (texto secundario sobre fondos oscuros).
  static const Color sageLight = Color(0xFFa8b8aa);

  /// Naranja principal (acento primario).
  static const Color orange = Color(0xFFe8670a);

  /// Naranja claro.
  static const Color orangeLight = Color(0xFFf5954a);

  /// Azul (acento secundario).
  static const Color blue = Color(0xFF2a7ab5);

  /// Verde (acento secundario).
  static const Color green = Color(0xFF5aaa3c);

  /// Niebla (fondo suave).
  static const Color mist = Color(0xFFede9e0);

  /// Borde.
  static const Color border = Color(0xFFcdc9be);
}

/// Tema global de la app Zéfiro Strix.
///
/// Replica el patrón tipográfico del portal:
/// - Texto general (display, headline, title, bodyLarge) en Cormorant Garamond (w300).
/// - Elementos técnicos / de interfaz (labels, bodyMedium/Small, botones) en Inconsolata.
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        secondary: AppColors.blue,
        surface: AppColors.paper,
      ),
      scaffoldBackgroundColor: AppColors.paper,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 57,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 45,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 36,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        titleLarge: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.cormorantGaramond(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        titleSmall: GoogleFonts.cormorantGaramond(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.cormorantGaramond(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        bodyMedium: GoogleFonts.inconsolata(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        bodySmall: GoogleFonts.inconsolata(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        labelLarge: GoogleFonts.inconsolata(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        labelMedium: GoogleFonts.inconsolata(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        labelSmall: GoogleFonts.inconsolata(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.inconsolata(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
