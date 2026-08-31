import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/config_model.dart';
import '../models/status_model.dart';
import '../models/sync_models.dart';

/// Simple connection state exposed to the UI, independent of any BLE package.
enum ConnectionState {
  connecting,
  connected,
  disconnected,
}

class BleService {
  static const String serviceUuid = "4d617b4f-4320-4e1b-b6c0-1e6a52a81ba9";
  static const String configUuid = "770440e9-947e-4983-a405-3fdd67dd43db";
  static const String statusUuid = "babdcdd4-83aa-45da-9444-1737d5ff6a2e";
  static const String timeSyncUuid = "398eaab7-1b17-4529-ab0d-d2ccedce80fe";
  static const String commandUuid = "62b3db56-e022-4efc-a2e7-af19c4f69a3f";

  FlutterReactiveBle? _bleInstance;

  /// Lazily creates the [FlutterReactiveBle] instance. The constructor eagerly
  /// initializes the platform, so we defer it until a BLE operation is actually
  /// needed (e.g. connect). This also keeps widget tests from touching the
  /// platform when no BLE operation is triggered.
  FlutterReactiveBle get _ble => _bleInstance ??= FlutterReactiveBle();

  String? _connectedDeviceId;

  final _statusController = StreamController<StatusModel>.broadcast();
  Stream<StatusModel> get statusStream => _statusController.stream;

  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;

  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _statusSubscription;

  /// Builds a [QualifiedCharacteristic] for the given characteristic UUID on
  /// the currently connected device.
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

    // Wait until the device reports connected (or the connection fails).
    await connectedCompleter.future;

    // Negotiate MTU
    try {
      await _ble.requestMtu(deviceId: deviceId, mtu: 247);
    } catch (e) {
      print("MTU request error: $e");
    }

    _setupStatusNotifications();
  }

  Future<void> disconnect() async {
    // Cancelling the connection subscription disconnects the device.
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

  Future<ConfigModel?> readConfig() async {
    if (_connectedDeviceId == null) return null;
    var value = await _ble.readCharacteristic(_characteristic(configUuid));
    String jsonStr = utf8.decode(value);
    return ConfigModel.fromJson(json.decode(jsonStr));
  }

  Future<void> writeConfig(ConfigModel config) async {
    if (_connectedDeviceId == null) return;
    String jsonStr = json.encode(config.toJson());
    await _ble.writeCharacteristicWithResponse(
      _characteristic(configUuid),
      value: utf8.encode(jsonStr),
    );
  }

  Future<void> syncTime(TimeSyncModel sync) async {
    if (_connectedDeviceId == null) return;
    String jsonStr = json.encode(sync.toJson());
    await _ble.writeCharacteristicWithResponse(
      _characteristic(timeSyncUuid),
      value: utf8.encode(jsonStr),
    );
  }

  Future<void> sendCommand(CommandModel command) async {
    if (_connectedDeviceId == null) return;
    String jsonStr = json.encode(command.toJson());
    await _ble.writeCharacteristicWithResponse(
      _characteristic(commandUuid),
      value: utf8.encode(jsonStr),
    );
  }
}
