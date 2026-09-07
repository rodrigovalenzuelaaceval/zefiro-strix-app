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

  final int? batPct;
  final double? batV;
  final bool? bmeOk;
  final double? tempC;
  final double? humPct;
  final double? presHpa;

  StatusModel({
    required this.version,
    required this.unitName,
    required this.rtcTime,
    required this.sdFreeMB,
    required this.sessions,
    required this.recordings,
    this.boardType,
    this.batPct,
    this.batV,
    this.bmeOk,
    this.tempC,
    this.humPct,
    this.presHpa,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) => _$StatusModelFromJson(json);
  Map<String, dynamic> toJson() => _$StatusModelToJson(this);
}
