// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigModel _$ConfigModelFromJson(Map<String, dynamic> json) => ConfigModel(
  stationName: json['stationName'] as String,
  projectName: json['projectName'] as String,
  researcher: json['researcher'] as String,
  unitName: json['unitName'] as String,
  utmZone: json['utmZone'] as String,
  utmEaste: (json['utmEaste'] as num).toInt(),
  utmNorte: (json['utmNorte'] as num).toInt(),
  morningStart: json['morningStart'] as String,
  morningEnd: json['morningEnd'] as String,
  nightStart: json['nightStart'] as String,
  nightEnd: json['nightEnd'] as String,
  recTime: (json['recTime'] as num).toInt(),
  pauseMs: (json['pauseMs'] as num).toInt(),
  volume: (json['volume'] as num).toInt(),
  gainFactor: (json['gainFactor'] as num).toInt(),
  trackCount: (json['trackCount'] as num).toInt(),
  totalSessions: (json['totalSessions'] as num).toInt(),
  totalRecordings: (json['totalRecordings'] as num).toInt(),
);

Map<String, dynamic> _$ConfigModelToJson(ConfigModel instance) =>
    <String, dynamic>{
      'stationName': instance.stationName,
      'projectName': instance.projectName,
      'researcher': instance.researcher,
      'unitName': instance.unitName,
      'utmZone': instance.utmZone,
      'utmEaste': instance.utmEaste,
      'utmNorte': instance.utmNorte,
      'morningStart': instance.morningStart,
      'morningEnd': instance.morningEnd,
      'nightStart': instance.nightStart,
      'nightEnd': instance.nightEnd,
      'recTime': instance.recTime,
      'pauseMs': instance.pauseMs,
      'volume': instance.volume,
      'gainFactor': instance.gainFactor,
      'trackCount': instance.trackCount,
      'totalSessions': instance.totalSessions,
      'totalRecordings': instance.totalRecordings,
    };

TrackModel _$TrackModelFromJson(Map<String, dynamic> json) => TrackModel(
  order: (json['order'] as num).toInt(),
  species: json['species'] as String,
  active: json['active'] as bool,
);

Map<String, dynamic> _$TrackModelToJson(TrackModel instance) =>
    <String, dynamic>{
      'order': instance.order,
      'species': instance.species,
      'active': instance.active,
    };
