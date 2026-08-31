// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSyncModel _$TimeSyncModelFromJson(Map<String, dynamic> json) =>
    TimeSyncModel(
      sysDate: json['sysDate'] as String,
      sysTime: json['sysTime'] as String,
    );

Map<String, dynamic> _$TimeSyncModelToJson(TimeSyncModel instance) =>
    <String, dynamic>{'sysDate': instance.sysDate, 'sysTime': instance.sysTime};

CommandModel _$CommandModelFromJson(Map<String, dynamic> json) =>
    CommandModel(shutdown: json['shutdown'] as bool?);

Map<String, dynamic> _$CommandModelToJson(CommandModel instance) =>
    <String, dynamic>{'shutdown': instance.shutdown};
