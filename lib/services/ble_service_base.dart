import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' show DiscoveredDevice;
import '../models/config_model.dart';
import '../models/status_model.dart';
import '../models/sync_models.dart';
import '../models/tracks_page_model.dart';

enum ConnectionState {
  connecting,
  connected,
  disconnected,
}

/// Contrato común entre BleService (dispositivo real por Bluetooth) y
/// MockBleService (simulador, sin hardware). Las pantallas dependen de este
/// tipo, no de la implementación concreta, así que pueden recibir cualquiera
/// de las dos sin cambiar nada más.
abstract class BleServiceBase {
  Stream<StatusModel> get statusStream;
  Stream<ConnectionState> get connectionStateStream;

  /// Chequea permisos/estado del adaptador antes de escanear. En el
  /// simulador no hay nada que chequear, así que siempre devuelve true de
  /// inmediato. [onMessage] recibe un mensaje para mostrar al usuario si
  /// algo no está listo (solo lo usa la implementación real).
  Future<bool> ensureReady({void Function(String message)? onMessage});

  Stream<DiscoveredDevice> scanForDevices();

  Future<void> connect(String deviceId);
  Future<void> disconnect();

  Future<ConfigModel?> readConfig();
  Future<void> writeConfig(ConfigModel config);

  Future<TracksPageModel> readTracksPage(int page);
  Future<void> writeTracksPage(TracksPageModel page);
  Future<List<TrackModel>> readAllTracks();
  Future<void> writeAllTracks(List<TrackModel> tracks, {int pageSize = 5});

  Future<void> syncTime(TimeSyncModel sync);
  Future<void> sendCommand(CommandModel command);
}
