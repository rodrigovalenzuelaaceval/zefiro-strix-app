import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/config_model.dart';
import '../utils/location_utils.dart';
import '../utils/sea_calculator.dart';

/// Captures the current GPS position and converts it to UTM coordinates.
///
/// The result (zone, easting, northing, accuracy) is shown to the user, who
/// can then accept the coordinates to store them into the provided [config].
///
/// V3.3.0: también ofrece Modo SEA (cálculo normativo de horarios a partir
/// de amanecer/atardecer). Igual que en portal.h, el cálculo usa las
/// coordenadas crudas del momento de la captura, no las UTM ya guardadas —
/// si se quiere recalcular más tarde, hay que volver a captar GPS.
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
  double? _rawLat;
  double? _rawLon;

  bool _seaMode = false;
  SeaSchedule? _seaSchedule;
  String? _seaError;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _loading = true;
      _error = null;
      _seaSchedule = null;
      _seaError = null;
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
        _rawLat = pos.latitude;
        _rawLon = pos.longitude;
      });

      if (_seaMode) _recalculateSea();
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

  void _recalculateSea() {
    if (_rawLat == null || _rawLon == null) {
      setState(() {
        _seaError = 'Se necesitan coordenadas GPS para el modo SEA. Capta la ubicación primero.';
        _seaSchedule = null;
      });
      return;
    }

    final schedule = SeaCalculator.calculate(lat: _rawLat!, lon: _rawLon!);
    setState(() {
      if (schedule == null) {
        _seaError = 'No se pudo calcular amanecer/atardecer para esta ubicación y fecha.';
        _seaSchedule = null;
      } else {
        _seaError = null;
        _seaSchedule = schedule;
      }
    });
  }

  void _onSeaModeChanged(bool value) {
    setState(() => _seaMode = value);
    if (value) _recalculateSea();
  }

  void _useCoordinates() {
    if (_utmZone == null || _easting == null || _northing == null) return;

    widget.config.utmZone = _utmZone!;
    widget.config.utmEaste = _easting!;
    widget.config.utmNorte = _northing!;

    if (_seaMode && _seaSchedule != null) {
      widget.config.morningStart = _seaSchedule!.morningStart;
      widget.config.morningEnd = _seaSchedule!.morningEnd;
      widget.config.nightStart = _seaSchedule!.nightStart;
      widget.config.nightEnd = _seaSchedule!.nightEnd;
    }

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
        const SizedBox(height: 16),
        const Divider(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Modo normativo SEA'),
          subtitle: const Text(
            'Calcula automáticamente los horarios: noche = 1h después del '
            'atardecer, mañana = 1h antes del amanecer.',
          ),
          value: _seaMode,
          onChanged: _onSeaModeChanged,
        ),
        if (_seaMode) _buildSeaResult(),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _useCoordinates,
          icon: const Icon(Icons.check),
          label: Text(_seaMode
              ? 'Usar estas coordenadas y horarios SEA'
              : 'Usar estas coordenadas'),
        ),
      ],
    );
  }

  Widget _buildSeaResult() {
    if (_seaError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _seaError!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final s = _seaSchedule;
    if (s == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horarios calculados para hoy', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              _buildInfoRow('Ciclo mañana', '${s.morningStart} – ${s.morningEnd}'),
              _buildInfoRow('Ciclo noche', '${s.nightStart} – ${s.nightEnd}'),
            ],
          ),
        ),
      ),
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
