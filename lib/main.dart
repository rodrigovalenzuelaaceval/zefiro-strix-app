import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/scanner_screen.dart';
import 'screens/device_screen.dart';
import 'services/ble_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ZefiroApp());
}

class ZefiroApp extends StatefulWidget {
  const ZefiroApp({super.key});

  @override
  State<ZefiroApp> createState() => _ZefiroAppState();
}

class _ZefiroAppState extends State<ZefiroApp> {
  final BleService _bleService = BleService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zéfiro Strix',
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'),
      ],
      locale: const Locale('es', 'CL'),
      // El splash ahora es nativo (flutter_native_splash), no una pantalla
      // Dart con temporizador artificial. Arrancamos directo en el scanner.
      initialRoute: '/scanner',
      routes: {
        '/scanner': (context) => ScannerScreen(bleService: _bleService),
        '/device': (context) => DeviceScreen(bleService: _bleService),
      },
    );
  }
}
