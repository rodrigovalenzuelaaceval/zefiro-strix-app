import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'ble_service_base.dart';
import '../models/config_model.dart';
import '../models/status_model.dart';
import '../models/sync_models.dart';
import '../models/tracks_page_model.dart';

export 'ble_service_base.dart' show ConnectionState, BleServiceBase;

class BleService implements BleServiceBase {
  static const String serviceUuid = "4d617b4f-4320-4e1b-b6c0-1e6a52a81ba9";
  static const String configUuid = "770440e9-947e-4983-a405-3fdd67dd43db";
  static const String statusUuid = "babdcdd4-83aa-45da-9444-1737d5ff6a2e";
  static const String timeSyncUuid = "398eaab7-1b17-4529-ab0d-d2ccedce80fe";
  static const String commandUuid = "62b3db56-e022-4efc-a2e7-af19c4f69a3f";
  static const String tracksPageSelectUuid = "ee9249c7-eb47-43ef-a8b8-132e9f24b7ed";
  static const String tracksDataUuid = "9d181ffd-a6ae-497b-96b2-719fb223531d";

  FlutterReactiveBle? _bleInstance;
  FlutterReactiveBle get _ble => _bleInstance ??= FlutterReactiveBle();

  String? _connectedDeviceId;

  final _statusController = StreamController<StatusModel>.broadcast();
  @override
  Stream<StatusModel> get statusStream => _statusController.stream;

  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  @override
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;

  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _statusSubscription;

  QualifiedCharacteristic _characteristic(String characteristicUuid) {
    final deviceId = _connectedDeviceId;
    if (deviceId == null) {
      throw StateError("No device connected");
    }
    return QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: deviceId,
    );
  }

  ConnectionState _mapConnectionState(DeviceConnectionState state) {
    switch (state) {
      case DeviceConnectionState.connecting:
        return ConnectionState.connecting;
      case DeviceConnectionState.connected:
        return ConnectionState.connected;
      case DeviceConnectionState.disconnecting:
      case DeviceConnectionState.disconnected:
        return ConnectionState.disconnected;
    }
  }

  // ==========================================================================
  // PERMISOS Y ESTADO DEL ADAPTADOR (migrado desde scanner_screen.dart, para
  // que MockBleService pueda tener su propia versión trivial del mismo
  // método sin que la pantalla necesite saber cuál implementación tiene)
  // ==========================================================================

  Future<bool> _requestPermissions({void Function(String)? onMessage}) async {
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
      onMessage?.call(
        'Bloqueaste el permiso de Bluetooth permanentemente. Actívalo manualmente desde Ajustes del sistema > Apps > Zéfiro Strix > Permisos.',
      );
      return false;
    }

    if (denied) {
      onMessage?.call('Permiso de Bluetooth denegado. Concede los permisos para escanear dispositivos.');
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

  @override
  Future<bool> ensureReady({void Function(String message)? onMessage}) async {
    final granted = await _requestPermissions(onMessage: onMessage);
    if (!granted) return false;

    var status = _ble.status;
    if (status == BleStatus.unknown) {
      status = await _ble.statusStream
          .firstWhere((s) => s != BleStatus.unknown)
          .timeout(const Duration(seconds: 3), onTimeout: () => status);
    }

    if (status != BleStatus.ready) {
      onMessage?.call(_statusMessage(status));
      return false;
    }

    return true;
  }

  @override
  Stream<DiscoveredDevice> scanForDevices() {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
    );
  }

  @override
  Future<void> connect(String deviceId) async {
    _connectedDeviceId = deviceId;

    final connectedCompleter = Completer<void>();

    _connectionSubscription?.cancel();
    _connectionSubscription = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen((update) {
      _connectionStateController.add(_mapConnectionState(update.connectionState));

      if (update.connectionState == DeviceConnectionState.connected) {
        if (!connectedCompleter.isCompleted) connectedCompleter.complete();
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        if (!connectedCompleter.isCompleted) {
          connectedCompleter.completeError(
            update.failure ?? Exception("Connection failed"),
          );
        }
        _cleanup();
      }
    });

    await connectedCompleter.future;

    try {
      await _ble.requestMtu(deviceId: deviceId, mtu: 247);
    } catch (e) {
      print("MTU request error: $e");
    }

    _setupStatusNotifications();
  }

  @override
  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _cleanup();
  }

  void _cleanup() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _connectedDeviceId = null;
  }

  Future<void> _setupStatusNotifications() async {
    final deviceId = _connectedDeviceId;
    if (deviceId == null) return;

    _statusSubscription?.cancel();
    _statusSubscription = _ble
        .subscribeToCharacteristic(_characteristic(statusUuid))
        .listen((value) {
      if (value.isNotEmpty) {
        try {
          String jsonStr = utf8.decode(value);
          _statusController.add(StatusModel.fromJson(json.decode(jsonStr)));
        } catch (e) {
          print("Error decoding status: $e");
        }
      }
    });
  }

  Future<List<int>> _readWithRetry(String uuid, {int maxAttempts = 4}) async {
    List<int> value = [];
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      value = await _ble.readCharacteristic(_characteristic(uuid));
      if (value.isNotEmpty) break;
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
    return value;
  }

  @override
  Future<ConfigModel?> readConfig() async {
    if (_connectedDeviceId == null) return null;

    final value = await _readWithRetry(configUuid);

    if (value.isEmpty) {
      throw Exception(
        "No se pudo leer la configuración del dispositivo tras varios intentos (respuesta vacía). Intenta reconectar.",
      );
    }

    String jsonStr = utf8.decode(value);

    try {
      return ConfigModel.fromJson(json.decode(jsonStr));
    } catch (e) {
      throw Exception("Configuración recibida pero con formato inválido: $e");
    }
  }

  @override
  Future<void> writeConfig(ConfigModel config) async {
    if (_connectedDeviceId == null) return;
    String jsonStr = json.encode(config.toJson());
    await _ble.writeCharacteristicWithResponse(
      _characteristic(configUuid),
      value: utf8.encode(jsonStr),
    );
  }

  @override
  Future<TracksPageModel> readTracksPage(int page) async {
    if (_connectedDeviceId == null) {
      throw StateError("No device connected");
    }

    await _ble.writeCharacteristicWithResponse(
      _characteristic(tracksPageSelectUuid),
      value: utf8.encode(page.toString()),
    );

    final value = await _readWithRetry(tracksDataUuid);

    if (value.isEmpty) {
      throw Exception(
        "No se pudo leer la página $page de pistas (respuesta vacía). Intenta de nuevo.",
      );
    }

    try {
      return TracksPageModel.fromJson(json.decode(utf8.decode(value)));
    } catch (e) {
      throw Exception("Página de pistas recibida con formato inválido: $e");
    }
  }

  @override
  Future<void> writeTracksPage(TracksPageModel page) async {
    if (_connectedDeviceId == null) return;
    String jsonStr = json.encode(page.toJson());
    await _ble.writeCharacteristicWithResponse(
      _characteristic(tracksDataUuid),
      value: utf8.encode(jsonStr),
    );
  }

  @override
  Future<List<TrackModel>> readAllTracks() async {
    final firstPage = await readTracksPage(0);
    final all = <TrackModel>[...firstPage.tracks];

    for (var p = 1; p < firstPage.totalPages; p++) {
      final page = await readTracksPage(p);
      all.addAll(page.tracks);
    }

    return all;
  }

  @override
  Future<void> writeAllTracks(List<TrackModel> tracks, {int pageSize = 5}) async {
    final totalTracks = tracks.length;
    final totalPages = totalTracks == 0 ? 1 : (totalTracks / pageSize).ceil();

    for (var p = 0; p < totalPages; p++) {
      final start = p * pageSize;
      final end = (start + pageSize > totalTracks) ? totalTracks : start + pageSize;
      final pageTracks = tracks.sublist(start, end);

      await writeTracksPage(TracksPageModel(
        page: p,
        totalPages: totalPages,
        totalTracks: totalTracks,
        tracks: pageTracks,
      ));
    }
  }

  @override
  Future<void> syncTime(TimeSyncModel sync) async {
    if (_connectedDeviceId == null) return;
    String jsonStr = json.encode(sync.toJson());
    await _ble.writeCharacteristicWithResponse(
      _characteristic(timeSyncUuid),
      value: utf8.encode(jsonStr),
    );
  }

  @override
  Future<void> sendCommand(CommandModel command) async {
    if (_connectedDeviceId == null) return;
    String jsonStr = json.encode(command.toJson());
    await _ble.writeCharacteristicWithResponse(
      _characteristic(commandUuid),
      value: utf8.encode(jsonStr),
    );
  }
}
