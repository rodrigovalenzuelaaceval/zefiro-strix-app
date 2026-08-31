import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Pantalla de bienvenida / splash de Zéfiro Strix.
///
/// Muestra un placeholder donde irá el logo real, el nombre de la app y una
/// breve descripción, antes de navegar al escáner.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/scanner');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Espaciador superior para centrar el bloque principal.
            const Spacer(),
            // Bloque central: logo placeholder + nombre + descripción.
            Column(
              children: [
                // Placeholder del logo (96x96) con borde sutil en naranja.
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.orange, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ZÉFIRO STRIX',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: AppColors.orange,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Monitoreo bioacústico nocturno · Tetrapoda',
                  style: GoogleFonts.inconsolata(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sageLight,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Pie de página con versión.
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Tetrapoda SpA · v1.6',
                style: GoogleFonts.inconsolata(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.sageLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
