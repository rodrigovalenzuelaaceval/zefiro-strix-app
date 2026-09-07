// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatusModel _$StatusModelFromJson(Map<String, dynamic> json) => StatusModel(
  version: json['version'] as String,
  unitName: json['unitName'] as String,
  rtcTime: json['rtcTime'] as String,
  sdFreeMB: (json['sdFreeMB'] as num).toInt(),
  sessions: (json['sessions'] as num).toInt(),
  recordings: (json['recordings'] as num).toInt(),
  boardType: json['boardType'] as String?,
  batPct: (json['batPct'] as num?)?.toInt(),
  batV: (json['batV'] as num?)?.toDouble(),
  bmeOk: json['bmeOk'] as bool?,
  tempC: (json['tempC'] as num?)?.toDouble(),
  humPct: (json['humPct'] as num?)?.toDouble(),
  presHpa: (json['presHpa'] as num?)?.toDouble(),
);

Map<String, dynamic> _$StatusModelToJson(StatusModel instance) =>
    <String, dynamic>{
      'version': instance.version,
      'unitName': instance.unitName,
      'rtcTime': instance.rtcTime,
      'sdFreeMB': instance.sdFreeMB,
      'sessions': instance.sessions,
      'recordings': instance.recordings,
      'boardType': instance.boardType,
      'batPct': instance.batPct,
      'batV': instance.batV,
      'bmeOk': instance.bmeOk,
      'tempC': instance.tempC,
      'humPct': instance.humPct,
      'presHpa': instance.presHpa,
    };
