import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' show DiscoveredDevice;
import 'ble_service_base.dart';
import '../models/config_model.dart';
import '../models/status_model.dart';
import '../models/sync_models.dart';
import '../models/tracks_page_model.dart';

/// Simulador de un Zéfiro Strix, sin necesidad de hardware real ni Bluetooth.
///
/// Se comporta como BleService: mismo contrato (BleServiceBase), mismos
/// tiempos aproximados de respuesta (con pequeños delays simulados para que
/// se sienta como una conexión real), y datos que cambian solos con el
/// tiempo para poder probar la pantalla de Estado sin conectar nada.
///
/// Todo vive en memoria: al cerrar la app se pierde, no hay persistencia
/// real (es un simulador, no un dispositivo).
class MockBleService implements BleServiceBase {
  static const String simulatedDeviceId = "SIMULADOR-001";
  static const String simulatedDeviceName = "ZefiroStrix-SIMULADOR";

  final _statusController = StreamController<StatusModel>.broadcast();
  @override
  Stream<StatusModel> get statusStream => _statusController.stream;

  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  @override
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;

  Timer? _statusTimer;
  final Random _random = Random();

  bool _connected = false;

  // Estado simulado que "vive" en el dispositivo falso.
  int _batPct = 87;
  double _batV = 12.4;
  double _tempC = 14.5;
  double _humPct = 62;
  double _presHpa = 1013;
  int _sdFreeMB = 30424;
  int _sessions = 3;
  int _recordings = 11;

  late ConfigModel _config;
  late List<TrackModel> _tracks;

  MockBleService() {
    _config = _defaultConfig();
    _tracks = _defaultTracks();
  }

  ConfigModel _defaultConfig() => ConfigModel(
        stationName: "Estación Simulada",
        projectName: "Proyecto Demo",
        researcher: "Investigador",
        unitName: "ZS-SIM",
        utmZone: "19H",
        utmEaste: 353070,
        utmNorte: 6297756,
        morningStart: "05:22",
        morningEnd: "06:22",
        nightStart: "19:55",
        nightEnd: "20:55",
        recTime: 40,
        pauseMs: 500,
        volume: 30,
        gainFactor: 3,
        trackCount: 7,
        totalSessions: _sessions,
        totalRecordings: _recordings,
      );

  List<TrackModel> _defaultTracks() => [
        TrackModel(order: 1, species: "Chuncho (Glaucidium nanum)", active: true),
        TrackModel(order: 2, species: "Concón (Strix rufipes)", active: true),
        TrackModel(order: 3, species: "Lechuza (Tyto alba)", active: true),
        TrackModel(order: 4, species: "Tucúquere (Bubo magellanicus)", active: true),
        TrackModel(order: 5, species: "Nuco (Asio flammeus)", active: true),
        TrackModel(order: 6, species: "Especie 6", active: false),
        TrackModel(order: 7, species: "Especie 7", active: false),
      ];

  @override
  Future<bool> ensureReady({void Function(String message)? onMessage}) async {
    // El simulador no necesita Bluetooth ni permisos reales.
    return true;
  }

  @override
  Stream<DiscoveredDevice> scanForDevices() async* {
    await Future.delayed(const Duration(milliseconds: 900));
    yield DiscoveredDevice(
      id: simulatedDeviceId,
      name: simulatedDeviceName,
      serviceData: const {},
      manufacturerData: Uint8List(0),
      rssi: -47,
      serviceUuids: const [],
    );
  }

  @override
  Future<void> connect(String deviceId) async {
    _connectionStateController.add(ConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 700));
    _connected = true;
    _connectionStateController.add(ConnectionState.connected);
    _startStatusSimulation();
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _statusTimer?.cancel();
    _connectionStateController.add(ConnectionState.disconnected);
  }

  void _startStatusSimulation() {
    _statusTimer?.cancel();
    _emitStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_connected) return;

      // Batería drena muy lento, para que se note si se deja la pantalla
      // abierta un rato, sin que llegue a 0 en una sesión normal de prueba.
      if (_batPct > 1 && _random.nextDouble() < 0.3) _batPct -= 1;
      _batV = 9.0 + (_batPct / 100) * 3.6; // ~9.0V (vacío) a ~12.6V (lleno)

      // Ambiente: pequeño jitter realista alrededor de un valor base.
      _tempC += (_random.nextDouble() - 0.5) * 0.4;
      _humPct += (_random.nextDouble() - 0.5) * 1.5;
      _humPct = _humPct.clamp(30, 95);
      _presHpa += (_random.nextDouble() - 0.5) * 0.6;

      _sdFreeMB -= _random.nextInt(3);

      _emitStatus();
    });
  }

  void _emitStatus() {
    _statusController.add(StatusModel(
      version: "3.3.0-SIM",
      unitName: _config.unitName,
      rtcTime: DateTime.now().toString().substring(0, 19),
      sdFreeMB: _sdFreeMB,
      sessions: _sessions,
      recordings: _recordings,
      boardType: "diy-wired",
      batPct: _batPct,
      batV: double.parse(_batV.toStringAsFixed(2)),
      bmeOk: true,
      tempC: double.parse(_tempC.toStringAsFixed(1)),
      humPct: double.parse(_humPct.toStringAsFixed(0)),
      presHpa: double.parse(_presHpa.toStringAsFixed(0)),
    ));
  }

  @override
  Future<ConfigModel?> readConfig() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return ConfigModel.fromJson(_config.toJson());
  }

  @override
  Future<void> writeConfig(ConfigModel config) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _config = ConfigModel.fromJson(config.toJson());
  }

  @override
  Future<TracksPageModel> readTracksPage(int page) async {
    const pageSize = 5;
    await Future.delayed(const Duration(milliseconds: 250));
    final totalPages = _tracks.isEmpty ? 1 : (_tracks.length / pageSize).ceil();
    final start = page * pageSize;
    final end = (start + pageSize > _tracks.length) ? _tracks.length : start + pageSize;
    final pageTracks = start < _tracks.length ? _tracks.sublist(start, end) : <TrackModel>[];

    return TracksPageModel(
      page: page,
      totalPages: totalPages,
      totalTracks: _tracks.length,
      tracks: pageTracks,
    );
  }

  @override
  Future<void> writeTracksPage(TracksPageModel page) async {
    const pageSize = 5;
    await Future.delayed(const Duration(milliseconds: 250));
    final start = page.page * pageSize;

    // Asegura tamaño suficiente antes de escribir en índices más allá del
    // final actual (por ejemplo, si el usuario agregó pistas nuevas).
    while (_tracks.length < start + page.tracks.length) {
      _tracks.add(TrackModel(order: _tracks.length + 1, species: "Especie", active: true));
    }

    for (var i = 0; i < page.tracks.length; i++) {
      _tracks[start + i] = page.tracks[i];
    }

    if (page.totalTracks < _tracks.length) {
      _tracks = _tracks.sublist(0, page.totalTracks);
    }
  }

  @override
  Future<List<TrackModel>> readAllTracks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tracks.map((t) => TrackModel.fromJson(t.toJson())).toList();
  }

  @override
  Future<void> writeAllTracks(List<TrackModel> tracks, {int pageSize = 5}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _tracks = tracks.map((t) => TrackModel.fromJson(t.toJson())).toList();
  }

  @override
  Future<void> syncTime(TimeSyncModel sync) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // No-op: no hay reloj real que sincronizar.
  }

  @override
  Future<void> sendCommand(CommandModel command) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (command.shutdown == true) {
      await disconnect();
    }
  }
}
