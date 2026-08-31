import 'package:json_annotation/json_annotation.dart';

part 'status_model.g.dart';

@JsonSerializable()
class StatusModel {
  final String version;
  final String unitName;
  final String rtcTime;
  final int sdFreeMB;
  final int sessions;
  final int recordings;
  final String? boardType;

  StatusModel({
    required this.version,
    required this.unitName,
    required this.rtcTime,
    required this.sdFreeMB,
    required this.sessions,
    required this.recordings,
    this.boardType,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) => _$StatusModelFromJson(json);
  Map<String, dynamic> toJson() => _$StatusModelToJson(this);
}
