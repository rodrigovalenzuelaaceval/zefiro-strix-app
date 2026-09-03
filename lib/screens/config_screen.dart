import 'package:flutter/material.dart';
import '../models/config_model.dart';
import '../theme/app_theme.dart';

/// Formulario completo de configuración del dispositivo.
///
/// V3.3.0: recibe [config] y [tracks] por separado, porque en el protocolo
/// BLE ya no viajan juntos (las pistas se leen/escriben paginadas, ver
/// BleService.readAllTracks()/writeAllTracks()). DeviceScreen se encarga de
/// juntarlos antes de abrir esta pantalla, y de escribir cada uno por su
/// característica correspondiente al guardar.
class ConfigScreen extends StatefulWidget {
  final ConfigModel config;
  final List<TrackModel> tracks;
  final Future<void> Function(ConfigModel updatedConfig) onSaveConfig;
  final Future<void> Function(List<TrackModel> updatedTracks) onSaveTracks;

  const ConfigScreen({
    super.key,
    required this.config,
    required this.tracks,
    required this.onSaveConfig,
    required this.onSaveTracks,
  });

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late ConfigModel _config;
  late List<TrackModel> _tracks;
  bool _isSaving = false;

  late TextEditingController _stationNameCtrl;
  late TextEditingController _projectNameCtrl;
  late TextEditingController _researcherCtrl;
  late TextEditingController _unitNameCtrl;
  late TextEditingController _recTimeCtrl;
  late TextEditingController _pauseMsCtrl;
  late TextEditingController _gainFactorCtrl;
  late List<TextEditingController> _trackControllers;

  @override
  void initState() {
    super.initState();
    // Copias locales editables, no tocamos los modelos originales hasta guardar.
    _config = ConfigModel.fromJson(widget.config.toJson());
    _tracks = widget.tracks
        .map((t) => TrackModel.fromJson(t.toJson()))
        .toList();

    _stationNameCtrl = TextEditingController(text: _config.stationName);
    _projectNameCtrl = TextEditingController(text: _config.projectName);
    _researcherCtrl = TextEditingController(text: _config.researcher);
    _unitNameCtrl = TextEditingController(text: _config.unitName);
    _recTimeCtrl = TextEditingController(text: _config.recTime.toString());
    _pauseMsCtrl = TextEditingController(text: _config.pauseMs.toString());
    _gainFactorCtrl = TextEditingController(text: _config.gainFactor.toString());
    _trackControllers =
        _tracks.map((t) => TextEditingController(text: t.species)).toList();
  }

  @override
  void dispose() {
    _stationNameCtrl.dispose();
    _projectNameCtrl.dispose();
    _researcherCtrl.dispose();
    _unitNameCtrl.dispose();
    _recTimeCtrl.dispose();
    _pauseMsCtrl.dispose();
    _gainFactorCtrl.dispose();
    for (final c in _trackControllers) {
      c.dispose();
    }
    super.dispose();
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({
    required String currentValue,
    required void Function(String) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(currentValue),
    );
    if (picked != null) {
      setState(() => onPicked(_formatTime(picked)));
    }
  }

  Future<void> _save() async {
    // Vuelca los controllers a los modelos antes de guardar.
    _config.stationName = _stationNameCtrl.text;
    _config.projectName = _projectNameCtrl.text;
    _config.researcher = _researcherCtrl.text;
    _config.unitName = _unitNameCtrl.text;
    _config.recTime = int.tryParse(_recTimeCtrl.text) ?? _config.recTime;
    _config.pauseMs = int.tryParse(_pauseMsCtrl.text) ?? _config.pauseMs;
    _config.gainFactor = int.tryParse(_gainFactorCtrl.text) ?? _config.gainFactor;
    for (var i = 0; i < _tracks.length; i++) {
      _tracks[i].species = _trackControllers[i].text;
    }
    _config.trackCount = _tracks.length;

    setState(() => _isSaving = true);
    try {
      // Dos escrituras BLE separadas: Config por un lado, Tracks (paginado)
      // por otro. Si la segunda falla, el usuario lo ve en el catch de abajo
      // y puede reintentar sin perder los cambios de identidad/horarios/audio,
      // que ya habrían quedado guardados.
      await widget.onSaveConfig(_config);
      await widget.onSaveTracks(_tracks);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper),
              ),
            )
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Identificación"),
          TextField(
            controller: _stationNameCtrl,
            decoration: const InputDecoration(labelText: "Nombre de estación"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _projectNameCtrl,
            decoration: const InputDecoration(labelText: "Proyecto"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _researcherCtrl,
            decoration: const InputDecoration(labelText: "Investigador"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _unitNameCtrl,
            decoration: const InputDecoration(labelText: "Nombre de unidad"),
          ),

          const SizedBox(height: 24),
          _sectionTitle("Ubicación (UTM)"),
          Card(
            color: AppColors.mist,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Zona: ${_config.utmZone}"),
                  Text("Este: ${_config.utmEaste}"),
                  Text("Norte: ${_config.utmNorte}"),
                  const SizedBox(height: 4),
                  Text(
                    "Solo lectura. Usa 'Update GPS (UTM)' en la pantalla anterior para actualizar estos valores.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle("Horarios"),
          _timeRow("Inicio mañana", _config.morningStart,
              (v) => _config.morningStart = v),
          _timeRow("Fin mañana", _config.morningEnd,
              (v) => _config.morningEnd = v),
          _timeRow("Inicio noche", _config.nightStart,
              (v) => _config.nightStart = v),
          _timeRow("Fin noche", _config.nightEnd,
              (v) => _config.nightEnd = v),

          const SizedBox(height: 24),
          _sectionTitle("Audio"),
          TextField(
            controller: _recTimeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Tiempo de grabación (segundos)"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pauseMsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Pausa entre pistas (ms)"),
          ),
          const SizedBox(height: 8),
          Text("Volumen: ${_config.volume}", style: Theme.of(context).textTheme.bodyMedium),
          Slider(
            value: _config.volume.toDouble().clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 100,
            label: _config.volume.toString(),
            onChanged: (v) => setState(() => _config.volume = v.round()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _gainFactorCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Factor de ganancia"),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle("Pistas (playback)"),
              Text(
                "${_tracks.length} de 30 máx.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          ...List.generate(_tracks.length, (i) {
            final track = _tracks[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text("${track.order}", style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _trackControllers[i],
                        decoration: const InputDecoration(labelText: "Especie", isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: track.active,
                      onChanged: (v) => setState(() => track.active = v),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.sage),
                      tooltip: "Eliminar pista",
                      onPressed: () => setState(() {
                        _tracks.removeAt(i);
                        _trackControllers.removeAt(i).dispose();
                        for (var j = 0; j < _tracks.length; j++) {
                          _tracks[j].order = j + 1;
                        }
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (_tracks.length < 30)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _tracks.add(TrackModel(
                  order: _tracks.length + 1,
                  species: "Nueva especie",
                  active: true,
                ));
                _trackControllers.add(TextEditingController(text: "Nueva especie"));
              }),
              icon: const Icon(Icons.add),
              label: const Text("Agregar pista"),
            )
          else
            Text(
              "Alcanzaste el máximo de 30 pistas.",
              style: Theme.of(context).textTheme.bodySmall,
            ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: const Text("Guardar configuración"),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      );

  Widget _timeRow(String label, String value, void Function(String) onSet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          TextButton(
            onPressed: () => _pickTime(currentValue: value, onPicked: onSet),
            child: Text(value, style: AppTextStyles.tabularValue(color: AppColors.blue)),
          ),
        ],
      ),
    );
  }
}
