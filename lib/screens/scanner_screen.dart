import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' show DiscoveredDevice;
import '../services/ble_service_base.dart';
import '../services/mock_ble_service.dart';
import 'device_screen.dart';

class ScannerScreen extends StatefulWidget {
  final BleServiceBase bleService;
  const ScannerScreen({super.key, required this.bleService});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  List<DiscoveredDevice> _scanResults = [];
  bool _isScanning = false;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  Timer? _scanTimeout;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      final ready = await widget.bleService.ensureReady(
        onMessage: (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
      );
      if (!ready) return;

      if (mounted) {
        setState(() {
          _isScanning = true;
          _scanResults = [];
        });
      }

      _scanSubscription?.cancel();
      _scanSubscription = widget.bleService.scanForDevices().listen((result) {
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

  Future<void> _connectTo(DiscoveredDevice result) async {
    try {
      await widget.bleService.connect(result.id);
      if (mounted) {
        Navigator.of(context).pushNamed('/device');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
      }
    }
  }

  /// Modo Simulación: crea un MockBleService independiente y navega directo
  /// a DeviceScreen con él, sin pasar por el escáner real. Útil para probar
  /// la app sin tener el dispositivo físico a mano (por ejemplo, en terreno).
  Future<void> _useSimulator() async {
    final mockService = MockBleService();
    await mockService.connect(MockBleService.simulatedDeviceId);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceScreen(bleService: mockService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar dispositivo Zéfiro Strix"),
        actions: [
          if (_isScanning)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            IconButton(onPressed: _startScan, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                return ListTile(
                  title: Text(result.name),
                  subtitle: Text(result.id),
                  trailing: const Icon(Icons.bluetooth),
                  onTap: () => _connectTo(result),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _useSimulator,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text("Modo simulación (sin hardware)"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
