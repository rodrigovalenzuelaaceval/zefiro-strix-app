import 'package:json_annotation/json_annotation.dart';

part 'sync_models.g.dart';

@JsonSerializable()
class TimeSyncModel {
  final String sysDate;
  final String sysTime;

  TimeSyncModel({
    required this.sysDate,
    required this.sysTime,
  });

  factory TimeSyncModel.fromJson(Map<String, dynamic> json) => _$TimeSyncModelFromJson(json);
  Map<String, dynamic> toJson() => _$TimeSyncModelToJson(this);
}

@JsonSerializable()
class CommandModel {
  final bool? shutdown;

  CommandModel({
    this.shutdown,
  });

  factory CommandModel.fromJson(Map<String, dynamic> json) => _$CommandModelFromJson(json);
  Map<String, dynamic> toJson() => _$CommandModelToJson(this);
}
