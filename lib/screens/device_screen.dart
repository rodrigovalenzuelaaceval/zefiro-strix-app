import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ble_service.dart';
import '../models/config_model.dart';
import '../models/status_model.dart';
import '../models/sync_models.dart';
import 'location_screen.dart';

class DeviceScreen extends StatefulWidget {
  final BleService bleService;
  const DeviceScreen({super.key, required this.bleService});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  StatusModel? _status;
  ConfigModel? _config;
  bool _isLoading = false;

  late TextEditingController _stationNameController;
  late TextEditingController _unitNameController;
  StreamSubscription<StatusModel>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _stationNameController = TextEditingController();
    _unitNameController = TextEditingController();

    _statusSubscription = widget.bleService.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
    _loadConfig();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _stationNameController.dispose();
    _unitNameController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await widget.bleService.readConfig();
      if (mounted) {
        setState(() {
          _config = config;
          _syncControllersFromConfig();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error reading config: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Updates the text controllers only when the config changed from an
  /// external source (e.g. a fresh read from the device or an import), so we
  /// don't clobber the user's cursor position/focus on every rebuild.
  void _syncControllersFromConfig() {
    final config = _config;
    if (config == null) return;
    if (_stationNameController.text != config.stationName) {
      _stationNameController.text = config.stationName;
    }
    if (_unitNameController.text != config.unitName) {
      _unitNameController.text = config.unitName;
    }
  }

  Future<void> _syncTime() async {
    try {
      final now = DateTime.now();
      final sync = TimeSyncModel(
        sysDate: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        sysTime: "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
      );
      await widget.bleService.syncTime(sync);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Time synced")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error syncing time: $e")));
    }
  }

  Future<void> _updateLocation() async {
    if (_config == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Read the configuration first")),
        );
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          config: _config!,
          onUseCoordinates: (updated) async {
            setState(() => _config = updated);
            try {
              await widget.bleService.writeConfig(updated);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Location updated & saved")),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error saving location: $e")),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _exportConfig() async {
    if (_config == null) return;
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/config.json');
      await file.writeAsString(json.encode(_config!.toJson()));
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Zéfiro Strix Config'),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error exporting config: $e")));
    }
  }

  Future<void> _importConfig() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null || picked.path == null) return;

      final file = File(picked.path!);
      final raw = await file.readAsString();
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException("El archivo no contiene un objeto JSON válido");
      }
      final imported = ConfigModel.fromJson(decoded);

      if (!mounted) return;
      setState(() {
        _config = imported;
        _syncControllersFromConfig();
      });

      // Ask whether to write it to the device immediately or just load it.
      final writeNow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Config importado"),
          content: const Text("¿Quieres escribir esta configuración al dispositivo ahora por BLE, o solo cargarla para revisarla antes de guardar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Solo cargar"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Escribir ahora"),
            ),
          ],
        ),
      );

      if (writeNow == true) {
        await _saveConfig();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Config cargado. Revisa y guarda cuando quieras.")),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error importing config: $e")));
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    try {
      await widget.bleService.writeConfig(_config!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Config saved")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving config: $e")));
    }
  }

  Future<void> _confirmShutdown() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Apagar el dispositivo?"),
        content: const Text("Se enviará el comando de apagado al dispositivo."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Apagar"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.bleService.sendCommand(CommandModel(shutdown: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comando de apagado enviado")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar apagado: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_status?.unitName ?? "Device Control"),
        actions: [
          IconButton(onPressed: _loadConfig, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _exportConfig, icon: const Icon(Icons.share)),
          IconButton(onPressed: _importConfig, icon: const Icon(Icons.file_open)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildSyncActions(),
                  const SizedBox(height: 16),
                  if (_config != null) _buildConfigEditor(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Text("Version: ${_status?.version ?? 'N/A'}"),
            Text("RTC Time: ${_status?.rtcTime ?? 'N/A'}"),
            Text("SD Free: ${_status?.sdFreeMB ?? 0} MB"),
            Text("Sessions: ${_status?.sessions ?? 0}"),
            Text("Recordings: ${_status?.recordings ?? 0}"),
            if (_status?.boardType != null) Text("Board: ${_status!.boardType}"),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActions() {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(onPressed: _syncTime, icon: const Icon(Icons.access_time), label: const Text("Sync Time")),
        ElevatedButton.icon(onPressed: _updateLocation, icon: const Icon(Icons.location_on), label: const Text("Update GPS (UTM)")),
        ElevatedButton.icon(
            onPressed: _confirmShutdown,
            icon: const Icon(Icons.power_settings_new),
            label: const Text("Shutdown"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red)),
      ],
    );
  }

  Widget _buildConfigEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Configuration", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _stationNameController,
          decoration: const InputDecoration(labelText: "Station Name"),
          onChanged: (v) => _config!.stationName = v,
        ),
        TextField(
          controller: _unitNameController,
          decoration: const InputDecoration(labelText: "Unit Name"),
          onChanged: (v) => _config!.unitName = v,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveConfig,
          child: const Text("Save Configuration"),
        ),
      ],
    );
  }
}
