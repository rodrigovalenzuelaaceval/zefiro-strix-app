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

    if (await _isAndroidSdkAtMost(30)) {
      permissions.add(Permission.locationWhenInUse);
    }

    final statuses = await permissions.request();

    final denied = statuses.values.any((status) => status.isDenied);
    final permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

    if (permanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Bloqueaste el permiso de Bluetooth permanentemente. Actívalo manualmente desde Ajustes del sistema > Apps > Zéfiro Strix > Permisos.',
            ),
            action: SnackBarAction(label: 'Abrir Ajustes', onPressed: openAppSettings),
          ),
        );
      }
      return false;
    }

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
      return false;
    }
  }

  String _statusMessage(BleStatus status) {
    switch (status) {
      case BleStatus.poweredOff:
        return 'El Bluetooth está apagado. Actívalo para escanear.';
      case BleStatus.unauthorized:
        return 'Faltan permisos de Bluetooth. Ve a Ajustes > Apps > Zéfiro Strix > Permisos y actívalos manualmente.';
      case BleStatus.locationServicesDisabled:
        return 'Activa la Ubicación (GPS) del sistema para poder escanear.';
      case BleStatus.unsupported:
        return 'Este teléfono no soporta Bluetooth Low Energy.';
      case BleStatus.unknown:
        return 'Estado del Bluetooth desconocido. Intenta de nuevo en un momento.';
      case BleStatus.ready:
        return '';
    }
  }

  Future<void> _startScan() async {
    try {
      // 1. Pedir permisos runtime PRIMERO — sin esto, el estado del adaptador
      //    nunca se reporta como "ready" en Android, sin importar cuántas
      //    veces se reintente.
      final granted = await _requestPermissions();
      if (!granted) return;

      // 2. Recién ahora chequear el estado real del adaptador. El plugin
      //    puede reportar "unknown" por un instante justo después de crearse
      //    (aún no le llega el primer aviso del sistema operativo), así que
      //    si eso pasa esperamos un poco al primer estado real antes de
      //    darnos por vencidos.
      var status = _ble.status;
      if (status == BleStatus.unknown) {
        status = await _ble.statusStream
            .firstWhere((s) => s != BleStatus.unknown)
            .timeout(const Duration(seconds: 3), onTimeout: () => status);
      }

      if (status != BleStatus.ready) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_statusMessage(status))),
          );
        }
        return;
      }

      // 3. Escanear
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
