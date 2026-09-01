import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
            const Spacer(),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ZÉFIRO STRIX',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.orange,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Monitoreo bioacústico nocturno · Tetrapoda',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.sageLight,
                      ),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Tetrapoda SpA · v1.6',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
