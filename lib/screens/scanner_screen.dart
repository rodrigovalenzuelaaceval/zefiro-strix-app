import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/ble_service.dart';

class ScannerScreen extends StatefulWidget {
  final BleService bleService;
  const ScannerScreen({super.key, required this.bleService});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  FlutterReactiveBle? _bleInstance;

  /// Lazily creates the [FlutterReactiveBle] instance. The constructor eagerly
  /// initializes the platform, so we defer it until a scan is actually started.
  /// This keeps widget tests from touching the platform when no BLE operation
  /// is triggered.
  FlutterReactiveBle get _ble => _bleInstance ??= FlutterReactiveBle();

  List<DiscoveredDevice> _scanResults = [];
  bool _isScanning = false;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  Timer? _scanTimeout;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    // On Android 11 (API 30) or lower, BLE scanning requires the location
    // permission to return results. On Android 12+ (API 31+) it is not needed
    // thanks to the `neverForLocation` flag in the manifest.
    if (await _isAndroidSdkAtMost(30)) {
      permissions.add(Permission.locationWhenInUse);
    }

    final statuses = await permissions.request();

    final denied = statuses.values.any((status) => status.isDenied);
    if (denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permiso de Bluetooth denegado. Concede los permisos para escanear dispositivos.',
            ),
            action: SnackBarAction(label: 'Reintentar', onPressed: _startScan),
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<bool> _isAndroidSdkAtMost(int maxSdk) async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt <= maxSdk;
    } catch (_) {
      // If we cannot determine the platform, assume it is not an old Android
      // version so we don't block the scan flow.
      return false;
    }
  }

  Future<void> _startScan() async {
    try {
      // 1. Check Bluetooth adapter is on
      if (_ble.status != BleStatus.ready) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El Bluetooth está apagado. Actívalo para escanear.'),
            ),
          );
        }
        return;
      }

      // 2. Request runtime permissions
      final granted = await _requestPermissions();
      if (!granted) return;

      // 3. Start scanning
      if (mounted) {
        setState(() {
          _isScanning = true;
          _scanResults = [];
        });
      }

      _scanSubscription?.cancel();
      _scanSubscription = _ble
          .scanForDevices(
            withServices: const [],
            scanMode: ScanMode.lowLatency,
          )
          .listen((result) {
        if (!mounted) return;
        if (!result.name.startsWith("ZefiroStrix")) return;
        setState(() {
          if (!_scanResults.any((d) => d.id == result.id)) {
            _scanResults.add(result);
          }
        });
      });

      // Stop scanning after 10 seconds
      _scanTimeout?.cancel();
      _scanTimeout = Timer(const Duration(seconds: 10), () {
        _scanSubscription?.cancel();
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar el escaneo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zéfiro Strix Scanner"),
        actions: [
          if (_isScanning)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            IconButton(onPressed: _startScan, icon: const Icon(Icons.refresh))
        ],
      ),
      body: ListView.builder(
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          return ListTile(
            title: Text(result.name),
            subtitle: Text(result.id),
            trailing: const Icon(Icons.bluetooth),
            onTap: () async {
              try {
                await widget.bleService.connect(result.id);
                if (mounted) {
                  Navigator.of(context).pushNamed('/device');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
                }
              }
            },
          );
        },
      ),
    );
  }
}
