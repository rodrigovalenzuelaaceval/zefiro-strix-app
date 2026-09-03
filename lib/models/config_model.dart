import 'package:json_annotation/json_annotation.dart';

part 'config_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ConfigModel {
  String stationName;
  String projectName;
  String researcher;
  String unitName;
  String utmZone;
  int utmEaste;
  int utmNorte;
  String morningStart;
  String morningEnd;
  String nightStart;
  String nightEnd;
  int recTime;
  int pauseMs;
  int volume;
  int gainFactor;
  // V3.3.0: tracks ya NO viaja en Config (puede superar el límite de 512
  // bytes de BLE con hasta 30 pistas). Ver TracksPageModel + BleService
  // readAllTracks()/writeAllTracks(). trackCount sí viaja aquí, para saber
  // cuántas pistas hay sin tener que leer Tracks primero.
  int trackCount;
  int totalSessions;
  int totalRecordings;

  ConfigModel({
    required this.stationName,
    required this.projectName,
    required this.researcher,
    required this.unitName,
    required this.utmZone,
    required this.utmEaste,
    required this.utmNorte,
    required this.morningStart,
    required this.morningEnd,
    required this.nightStart,
    required this.nightEnd,
    required this.recTime,
    required this.pauseMs,
    required this.volume,
    required this.gainFactor,
    required this.trackCount,
    required this.totalSessions,
    required this.totalRecordings,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) => _$ConfigModelFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigModelToJson(this);
}

@JsonSerializable()
class TrackModel {
  int order;
  String species;
  bool active;

  TrackModel({
    required this.order,
    required this.species,
    required this.active,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) => _$TrackModelFromJson(json);
  Map<String, dynamic> toJson() => _$TrackModelToJson(this);
}
