import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual de Tetrapoda, según Manual de Identidad v2.
///
/// Montserrat: identidad y jerarquía (splash, títulos superiores). Nunca en
/// listas largas ni tablas de datos.
/// Inter: ~95% de la interfaz (lecturas, botones, formularios, listas).
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF10110E); // Negro de marca
  static const Color paragraphGray = Color(0xFF44403C); // Gris de párrafos
  static const Color paper = Color(0xFFF4F1EA);
  static const Color mist = Color(0xFFEDE9E0);
  static const Color border = Color(0xFFCDC9BE);

  static const Color orange = Color(0xFFE8670A); // único color de acción/CTA
  static const Color orangeLight = Color(0xFFF5954A);
  static const Color blue = Color(0xFF2A7AB5); // único color de dato/precisión técnica
  static const Color green = Color(0xFF5AAA3C); // único color de confirmación
  static const Color sage = Color(0xFF6B7C6E);
  static const Color sageLight = Color(0xFFA8B8AA);
}

/// Estilo de texto para valores numéricos que deben alinearse (lecturas,
/// contadores, coordenadas). Usa Inter con tabular-nums, NUNCA monoespaciada.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle tabularValue({double fontSize = 16, Color? color}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Para volcado técnico crudo real (logs, versión de firmware, rutas de
  /// archivo). Única situación donde corresponde monoespaciada.
  static TextStyle rawTechnical({double fontSize = 13, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color ?? AppColors.paragraphGray,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        onPrimary: AppColors.ink, // texto sobre naranjo = negro, no blanco (manual v2)
        secondary: AppColors.blue,
        surface: AppColors.paper,
      ),
      scaffoldBackgroundColor: AppColors.paper,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // Montserrat: splash y títulos superiores de pantalla únicamente.
        displayLarge: GoogleFonts.montserrat(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.ink),
        displayMedium: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.ink),
        displaySmall: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink),
        headlineLarge: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
        headlineMedium: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
        headlineSmall: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
        titleLarge: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
        // Inter: resto de la interfaz. Mínimo 14sp, 16sp para valores críticos.
        // Nunca peso ≤300 en texto funcional (legibilidad de campo, manual v2).
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
        titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.paragraphGray),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.paragraphGray),
        bodySmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.paragraphGray),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        labelMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        labelSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.paper),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 44), // objetivo táctil mínimo, manual v2
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          foregroundColor: AppColors.ink,
        ),
      ),
    );
  }
}
