import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ble_service_base.dart';
import '../models/config_model.dart';
import '../models/status_model.dart';
import '../models/sync_models.dart';
import '../theme/app_theme.dart';
import '../utils/location_utils.dart';
import '../utils/sea_calculator.dart';

/// Pantalla única y continua: Estado + Configuración completa fusionados,
/// igual que el portal web (dashboard arriba, secciones numeradas 01-05
/// abajo, todo visible, nada detrás de un botón opcional).
class DeviceScreen extends StatefulWidget {
  final BleServiceBase bleService;
  const DeviceScreen({super.key, required this.bleService});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  StatusModel? _status;
  ConfigModel? _config;
  List<TrackModel>? _tracks;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isGpsLoading = false;
  bool _connected = true;

  StreamSubscription<StatusModel>? _statusSubscription;
  StreamSubscription<ConnectionState>? _connectionSubscription;

  // Identificación
  late TextEditingController _stationNameCtrl;
  late TextEditingController _projectNameCtrl;
  late TextEditingController _researcherCtrl;
  late TextEditingController _unitNameCtrl;

  // Audio
  late TextEditingController _recTimeCtrl;
  late TextEditingController _pauseMsCtrl;
  late TextEditingController _gainFactorCtrl;

  // Pistas
  List<TextEditingController> _commonNameControllers = [];
  List<TextEditingController> _scientificNameControllers = [];

  // Ubicación / SEA
  double? _rawLat;
  double? _rawLon;
  double? _gpsAccuracy;
  bool _seaMode = false;
  SeaSchedule? _seaSchedule;
  String? _seaError;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _statusSubscription = widget.bleService.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
    _connectionSubscription = widget.bleService.connectionStateStream.listen((state) {
      if (mounted) setState(() => _connected = state == ConnectionState.connected);
    });
    _loadAll();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();
    _stationNameCtrl.dispose();
    _projectNameCtrl.dispose();
    _researcherCtrl.dispose();
    _unitNameCtrl.dispose();
    _recTimeCtrl.dispose();
    _pauseMsCtrl.dispose();
    _gainFactorCtrl.dispose();
    for (final c in _commonNameControllers) {
      c.dispose();
    }
    for (final c in _scientificNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final config = await widget.bleService.readConfig();
      final tracks = await widget.bleService.readAllTracks();
      if (mounted) {
        setState(() {
          _config = config;
          _tracks = tracks;
          _syncControllers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al leer configuración: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncControllers() {
    final c = _config;
    if (c == null) return;
    _stationNameCtrl = TextEditingController(text: c.stationName);
    _projectNameCtrl = TextEditingController(text: c.projectName);
    _researcherCtrl = TextEditingController(text: c.researcher);
    _unitNameCtrl = TextEditingController(text: c.unitName);
    _recTimeCtrl = TextEditingController(text: c.recTime.toString());
    _pauseMsCtrl = TextEditingController(text: c.pauseMs.toString());
    _gainFactorCtrl = TextEditingController(text: c.gainFactor.toString());
    _commonNameControllers = (_tracks ?? [])
        .map((t) => TextEditingController(text: t.commonName))
        .toList();
    _scientificNameControllers = (_tracks ?? [])
        .map((t) => TextEditingController(text: t.scientificName))
        .toList();
  }
  // ==========================================================================
  // GPS + Modo SEA (inline, sin pantalla aparte — igual que el portal, que
  // reusa las coordenadas crudas del momento de la captura dentro de la
  // misma sesión)
  // ==========================================================================

  Future<void> _captureGps() async {
    setState(() {
      _isGpsLoading = true;
      _gpsError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _gpsError = 'El servicio de ubicación está desactivado.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _gpsError = 'Permiso de ubicación denegado.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _gpsError = 'Permiso denegado permanentemente. Actívalo en Ajustes.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final utm = LocationUtils.latLonToUTM(pos.latitude, pos.longitude);

      setState(() {
        _rawLat = pos.latitude;
        _rawLon = pos.longitude;
        _gpsAccuracy = pos.accuracy;
        _config?.utmZone = utm['utmZone'] as String;
        _config?.utmEaste = utm['utmEaste'] as int;
        _config?.utmNorte = utm['utmNorte'] as int;
      });

      if (_seaMode) _recalculateSea();
    } catch (e) {
      setState(() => _gpsError = 'No se pudo obtener la ubicación: $e');
    } finally {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  void _recalculateSea() {
    if (_rawLat == null || _rawLon == null) {
      setState(() {
        _seaError = 'Captura la ubicación GPS primero para usar el modo SEA.';
        _seaSchedule = null;
      });
      return;
    }
    final schedule = SeaCalculator.calculate(lat: _rawLat!, lon: _rawLon!);
    setState(() {
      if (schedule == null) {
        _seaError = 'No se pudo calcular amanecer/atardecer para esta ubicación.';
        _seaSchedule = null;
      } else {
        _seaError = null;
        _seaSchedule = schedule;
        _config?.morningStart = schedule.morningStart;
        _config?.morningEnd = schedule.morningEnd;
        _config?.nightStart = schedule.nightStart;
        _config?.nightEnd = schedule.nightEnd;
      }
    });
  }

  void _setMode(bool sea) {
    setState(() => _seaMode = sea);
    if (sea) _recalculateSea();
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(String currentValue, void Function(String) onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: _parseTime(currentValue));
    if (picked != null) setState(() => onPicked(_formatTimeOfDay(picked)));
  }

  // ==========================================================================
  // Guardar / Sincronizar / Cerrar
  // ==========================================================================

  Future<void> _syncTime() async {
    try {
      final now = DateTime.now();
      await widget.bleService.syncTime(TimeSyncModel(
        sysDate: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        sysTime: "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hora sincronizada")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al sincronizar hora: $e")));
      }
    }
  }

  Future<void> _saveAll() async {
    if (_config == null || _tracks == null) return;

    _config!.stationName = _stationNameCtrl.text;
    _config!.projectName = _projectNameCtrl.text;
    _config!.researcher = _researcherCtrl.text;
    _config!.unitName = _unitNameCtrl.text;
    _config!.recTime = int.tryParse(_recTimeCtrl.text) ?? _config!.recTime;
    _config!.pauseMs = int.tryParse(_pauseMsCtrl.text) ?? _config!.pauseMs;
    _config!.gainFactor = int.tryParse(_gainFactorCtrl.text) ?? _config!.gainFactor;
    for (var i = 0; i < _tracks!.length; i++) {
      _tracks![i].updateNames(
        commonName: _commonNameControllers[i].text,
        scientificName: _scientificNameControllers[i].text,
      );
    }
    _config!.trackCount = _tracks!.length;

    setState(() => _isSaving = true);
    try {
      await widget.bleService.writeConfig(_config!);
      await widget.bleService.writeAllTracks(_tracks!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuración guardada")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmCloseAndArm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Finalizar configuración?"),
        content: const Text(
          "El dispositivo comenzará a operar según el ciclo programado. Guarda la configuración antes de continuar si hiciste cambios.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Finalizar")),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.bleService.sendCommand(CommandModel(shutdown: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Zéfiro Strix configurado y operando")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _exportConfig() async {
    if (_config == null || _tracks == null) return;
    try {
      final bundle = {
        "config": _config!.toJson(),
        "tracks": _tracks!.map((t) => t.toJson()).toList(),
      };
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/config.json');
      await file.writeAsString(json.encode(bundle));
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Zéfiro Strix Config'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al exportar: $e")));
      }
    }
  }

  Future<void> _importConfig() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
      if (picked == null || picked.path == null) return;
      final raw = await File(picked.path!).readAsString();
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['config'] is! Map<String, dynamic> ||
          decoded['tracks'] is! List) {
        throw const FormatException("Formato de archivo no reconocido.");
      }
      final importedConfig = ConfigModel.fromJson(decoded['config'] as Map<String, dynamic>);
      final importedTracks = (decoded['tracks'] as List)
          .map((t) => TrackModel.fromJson(t as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _config = importedConfig;
        _tracks = importedTracks;
        _syncControllers();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Config importado. Revisa y guarda cuando quieras.")),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
      }
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: _buildHeader(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                ..._buildDashboard(),
                const SizedBox(height: 20),
                _sectionHeader("01", "Identificación"),
                _fieldBox(_stationNameCtrl, "Nombre de estación"),
                _fieldBox(_projectNameCtrl, "Proyecto"),
                _fieldBox(_researcherCtrl, "Investigador"),
                _fieldBox(_unitNameCtrl, "Nombre de unidad"),
                const SizedBox(height: 20),
                _sectionHeader("02", "Ubicación y hora"),
                _buildLocationSection(),
                const SizedBox(height: 12),
                _outlinedActionButton("Sincronizar hora", Icons.access_time, _syncTime),
                const SizedBox(height: 20),
                _sectionHeader("03", "Horarios de ciclo"),
                _buildModeTabs(),
                const SizedBox(height: 12),
                _buildScheduleFields(),
                const SizedBox(height: 20),
                _sectionHeader("04", "Grabación"),
                _secondsPickerField(_recTimeCtrl, "Tiempo de grabación", min: 5, max: 120),
                _fieldBox(_gainFactorCtrl, "Factor de ganancia", numeric: true),
                const SizedBox(height: 20),
                _sectionHeader("05", "Especies y orden"),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Sugerido: menor a mayor tamaño corporal, rapaces cazadoras al final.",
                    style: TextStyle(color: AppColors.sageLight, fontSize: 11),
                  ),
                ),
                _buildTracksReorderable(),
                _addTrackButton(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAll,
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text("Guardar configuración"),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(onPressed: _exportConfig, icon: const Icon(Icons.share, size: 16), label: const Text("Exportar")),
                    TextButton.icon(onPressed: _importConfig, icon: const Icon(Icons.file_open, size: 16), label: const Text("Importar")),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _confirmCloseAndArm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text("Cerrar y armar equipo", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: AppColors.ink,
      elevation: 0,
      titleSpacing: 12,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/icon/icon.png', width: 40, height: 40, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ZÉFIRO STRIX",
                style: TextStyle(color: AppColors.orange, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              Text(
                _status?.unitName ?? "Dispositivo",
                style: TextStyle(color: AppColors.paper, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connected ? AppColors.green : AppColors.sage,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _connected ? "Conectado" : "Sin conexión",
                    style: TextStyle(color: AppColors.sageLight, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "Tetrapoda®",
                style: TextStyle(color: AppColors.sage, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDashboard() {
    final rtc = _status?.rtcTime;
    String horaTxt = 'N/D';
    String fechaTxt = 'N/D';
    if (rtc != null && rtc.length >= 19) {
      try {
        final dt = DateTime.parse(rtc.replaceFirst(' ', 'T'));
        horaTxt = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
        const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
        fechaTxt = '${dias[dt.weekday - 1]}, ${dt.day} de ${meses[dt.month - 1]} de ${dt.year}';
      } catch (_) {}
    }

    return [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _dashCard("Hora", horaTxt, tabular: true)),
            const SizedBox(width: 8),
            Expanded(child: _dashCard("Fecha", fechaTxt, small: true)),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _dashCard("SD libre", "${_status?.sdFreeMB ?? 0} MB", muted: true)),
          const SizedBox(width: 8),
          Expanded(child: _dashCard("Grabaciones", "${_status?.recordings ?? 0}", muted: true)),
          const SizedBox(width: 8),
          Expanded(child: _dashCard("Sesiones", "${_status?.sessions ?? 0}", muted: true)),
        ],
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("v${_status?.version ?? '—'}", style: TextStyle(color: AppColors.sageLight, fontSize: 10)),
            Text(_status?.boardType ?? '—', style: TextStyle(color: AppColors.sageLight, fontSize: 10)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_status?.batPct != null || _status?.batV != null) _batteryCard(),
      if (_status?.bmeOk == true) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _envCard("Temp.", _status!.tempC != null ? "${_status!.tempC!.toStringAsFixed(1)}°" : "N/D")),
            const SizedBox(width: 8),
            Expanded(child: _envCard("Humedad", _status!.humPct != null ? "${_status!.humPct!.toStringAsFixed(0)}%" : "N/D")),
            const SizedBox(width: 8),
            Expanded(child: _envCard("Presión", _status!.presHpa != null ? _status!.presHpa!.toStringAsFixed(0) : "N/D")),
          ],
        ),
      ],
    ];
  }

  Widget _dashCard(String label, String value, {bool tabular = false, bool small = false, bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: muted ? AppColors.mist.withValues(alpha: 0.12) : AppColors.paper,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: AppColors.sage, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(
            value,
            style: tabular
                ? AppTextStyles.tabularValue(fontSize: 16, color: muted ? AppColors.paper : AppColors.ink)
                : TextStyle(fontSize: small ? 12 : 15, fontWeight: FontWeight.w700, color: muted ? AppColors.paper : AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _envCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: AppColors.blue, fontSize: 15, fontWeight: FontWeight.w700)),
          Text(label.toUpperCase(), style: TextStyle(color: AppColors.sage, fontSize: 8, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _batteryCard() {
    final pct = _status?.batPct;
    final volt = _status?.batV;
    Color barColor = AppColors.green;
    if (pct != null) {
      if (pct <= 15) {
        barColor = Colors.red;
      } else if (pct <= 30) {
        barColor = AppColors.orange;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("BATERÍA", style: TextStyle(color: AppColors.sage, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              if (volt != null)
                Text("${volt.toStringAsFixed(2)} V", style: AppTextStyles.tabularValue(fontSize: 12, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct != null ? pct / 100 : 0,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(pct != null ? "$pct%" : "N/D", style: TextStyle(color: barColor, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String num, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(num, style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: AppColors.paper, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _fieldBox(TextEditingController ctrl, String label, {bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: AppColors.paper, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.sageLight, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF1C1E19),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.orange)),
        ),
      ),
    );
  }

  Widget _outlinedActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.orange),
        label: Text(label, style: TextStyle(color: AppColors.paper)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1C1E19), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_config != null) ...[
            Text("Zona: ${_config!.utmZone}   Este: ${_config!.utmEaste}   Norte: ${_config!.utmNorte}",
                style: TextStyle(color: AppColors.sageLight, fontSize: 12)),
            if (_gpsAccuracy != null)
              Text("Precisión: ${_gpsAccuracy!.toStringAsFixed(1)} m", style: TextStyle(color: AppColors.sageLight, fontSize: 11)),
            const SizedBox(height: 8),
          ],
          if (_gpsError != null) ...[
            Text(_gpsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGpsLoading ? null : _captureGps,
              icon: _isGpsLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.location_on, size: 18, color: AppColors.orange),
              label: Text("Capturar ubicación GPS", style: TextStyle(color: AppColors.paper)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(child: _modeTab("Manual", !_seaMode, () => _setMode(false))),
          Expanded(child: _modeTab("Modo SEA", _seaMode, () => _setMode(true))),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? AppColors.ink : AppColors.sageLight,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleFields() {
    if (_config == null) return const SizedBox.shrink();

    if (_seaMode) {
      if (_seaError != null) {
        return Text(_seaError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13));
      }
      if (_seaSchedule == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1C1E19), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Dos ciclos de 1 hora: uno tras el atardecer, otro antes del amanecer.",
                style: TextStyle(color: AppColors.sageLight, fontSize: 11),
              ),
            ),
            _scheduleRow("Ciclo mañana", "${_seaSchedule!.morningStart} – ${_seaSchedule!.morningEnd}"),
            _scheduleRow("Ciclo noche", "${_seaSchedule!.nightStart} – ${_seaSchedule!.nightEnd}"),
          ],
        ),
      );
    }

    return Column(
      children: [
        _timeButton("Inicio mañana", _config!.morningStart, (v) => setState(() => _config!.morningStart = v)),
        _timeButton("Fin mañana", _config!.morningEnd, (v) => setState(() => _config!.morningEnd = v)),
        _timeButton("Inicio noche", _config!.nightStart, (v) => setState(() => _config!.nightStart = v)),
        _timeButton("Fin noche", _config!.nightEnd, (v) => setState(() => _config!.nightEnd = v)),
      ],
    );
  }

  Widget _scheduleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.sageLight, fontSize: 13)),
          Text(value, style: AppTextStyles.tabularValue(fontSize: 13, color: AppColors.blue)),
        ],
      ),
    );
  }

  Widget _timeButton(String label, String value, void Function(String) onSet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1C1E19),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickTime(value, onSet),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: AppColors.paper, fontSize: 13)),
                Row(
                  children: [
                    Text(value, style: AppTextStyles.tabularValue(fontSize: 14, color: AppColors.blue)),
                    const SizedBox(width: 6),
                    Icon(Icons.edit, size: 14, color: AppColors.sage),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondsPickerField(TextEditingController ctrl, String label, {required int min, required int max}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1C1E19),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickSeconds(ctrl, min: min, max: max),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: AppColors.paper, fontSize: 13)),
                Row(
                  children: [
                    Text("${ctrl.text} s", style: AppTextStyles.tabularValue(fontSize: 14, color: AppColors.blue)),
                    const SizedBox(width: 6),
                    Icon(Icons.edit, size: 14, color: AppColors.sage),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickSeconds(TextEditingController ctrl, {required int min, required int max}) async {
    final current = int.tryParse(ctrl.text) ?? min;
    final initialIndex = (current - min).clamp(0, max - min);
    int selected = current;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1E19),
      builder: (context) {
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (index) => selected = min + index,
                  children: List.generate(
                    max - min + 1,
                    (i) => Center(
                      child: Text("${min + i} s", style: TextStyle(color: AppColors.paper, fontSize: 16)),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Listo", style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() => ctrl.text = selected.toString());
  }

  Widget _buildTracksReorderable() {
    if (_tracks == null) return const SizedBox.shrink();
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final track = _tracks!.removeAt(oldIndex);
          _tracks!.insert(newIndex, track);
          final commonCtrl = _commonNameControllers.removeAt(oldIndex);
          _commonNameControllers.insert(newIndex, commonCtrl);
          final sciCtrl = _scientificNameControllers.removeAt(oldIndex);
          _scientificNameControllers.insert(newIndex, sciCtrl);
          for (var i = 0; i < _tracks!.length; i++) {
            _tracks![i].order = i + 1;
          }
        });
      },
      children: List.generate(_tracks!.length, (i) => _trackRow(i)),
    );
  }

  Widget _trackRow(int i) {
    final track = _tracks![i];
    return Container(
      key: ValueKey(_commonNameControllers[i]),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF1C1E19), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_handle, color: AppColors.sage, size: 20),
            ),
          ),
          SizedBox(width: 22, child: Text("${track.order}", style: TextStyle(color: AppColors.sageLight, fontSize: 13))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _commonNameControllers[i],
                  style: TextStyle(color: AppColors.paper, fontSize: 13),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Nombre común'),
                ),
                TextField(
                  controller: _scientificNameControllers[i],
                  style: TextStyle(color: AppColors.sageLight, fontSize: 12, fontStyle: FontStyle.italic),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Nombre científico'),
                ),
              ],
            ),
          ),
          Switch(
            value: track.active,
            activeThumbColor: AppColors.green,
            onChanged: (v) => setState(() => track.active = v),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.sage, size: 20),
            onPressed: () => setState(() {
              _tracks!.removeAt(i);
              _commonNameControllers.removeAt(i).dispose();
              _scientificNameControllers.removeAt(i).dispose();
              for (var j = 0; j < _tracks!.length; j++) {
                _tracks![j].order = j + 1;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _addTrackButton() {
    if (_tracks == null || _tracks!.length >= 30) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: () => setState(() {
        final nuevo = TrackModel(order: _tracks!.length + 1, species: "Nueva especie", active: true);
        _tracks!.add(nuevo);
        _commonNameControllers.add(TextEditingController(text: nuevo.commonName));
        _scientificNameControllers.add(TextEditingController(text: nuevo.scientificName));
      }),
      icon: Icon(Icons.add, color: AppColors.orange),
      label: Text("Agregar pista", style: TextStyle(color: AppColors.paper)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/pluma.png', width: 16, height: 16, errorBuilder: (_, _, _) => const SizedBox.shrink()),
            const SizedBox(width: 6),
            Text("Tetrapoda® SpA · Zéfiro Strix v1.6.0", style: TextStyle(color: AppColors.sageLight, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

