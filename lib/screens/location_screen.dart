import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/config_model.dart';
import '../utils/location_utils.dart';

/// Captures the current GPS position and converts it to UTM coordinates.
///
/// The result (zone, easting, northing, accuracy) is shown to the user, who
/// can then accept the coordinates to store them into the provided [config].
class LocationScreen extends StatefulWidget {
  final ConfigModel config;
  final void Function(ConfigModel updated) onUseCoordinates;

  const LocationScreen({
    super.key,
    required this.config,
    required this.onUseCoordinates,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _loading = false;
  String? _error;
  String? _utmZone;
  int? _easting;
  int? _northing;
  double? _accuracy;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error =
              'El servicio de ubicación está desactivado. Actívalo e inténtalo de nuevo.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error =
                'Permiso de ubicación denegado. Concede el permiso e inténtalo de nuevo.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'El permiso de ubicación fue denegado de forma permanente. Habilítalo desde los ajustes del sistema e inténtalo de nuevo.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final utm = LocationUtils.latLonToUTM(pos.latitude, pos.longitude);

      setState(() {
        _utmZone = utm['utmZone'] as String;
        _easting = utm['utmEaste'] as int;
        _northing = utm['utmNorte'] as int;
        _accuracy = pos.accuracy;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo obtener la ubicación: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _useCoordinates() {
    if (_utmZone == null || _easting == null || _northing == null) return;

    widget.config.utmZone = _utmZone!;
    widget.config.utmEaste = _easting!;
    widget.config.utmNorte = _northing!;

    widget.onUseCoordinates(widget.config);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capturar ubicación GPS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Esperando GPS...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Coordenadas UTM',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildInfoRow('Zona UTM', _utmZone ?? 'N/A'),
        _buildInfoRow('Este', _easting?.toString() ?? 'N/A'),
        _buildInfoRow('Norte', _northing?.toString() ?? 'N/A'),
        _buildInfoRow(
          'Precisión',
          _accuracy != null ? '${_accuracy!.toStringAsFixed(1)} m' : 'N/A',
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _useCoordinates,
          icon: const Icon(Icons.check),
          label: const Text('Usar estas coordenadas'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}