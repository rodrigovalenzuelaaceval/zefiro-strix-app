import 'config_model.dart';

/// Una página del catálogo de pistas (ver ble_service.dart y
/// docs/zefiro_ble_protocol_v1.md sección 6). Se escribe a mano (sin
/// json_serializable/build_runner) porque es un modelo simple y así evita
/// depender de la generación de código para este archivo puntual.
class TracksPageModel {
  final int page;
  final int totalPages;
  final int totalTracks;
  final List<TrackModel> tracks;

  TracksPageModel({
    required this.page,
    required this.totalPages,
    required this.totalTracks,
    required this.tracks,
  });

  factory TracksPageModel.fromJson(Map<String, dynamic> json) {
    return TracksPageModel(
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
      totalTracks: json['totalTracks'] as int,
      tracks: (json['tracks'] as List<dynamic>)
          .map((t) => TrackModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'totalPages': totalPages,
      'totalTracks': totalTracks,
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }
}
