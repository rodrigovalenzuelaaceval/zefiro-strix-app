import 'package:utm/utm.dart';

class LocationUtils {
  /// Converts Lat/Lon to UTM following the logic expected by the Zefiro Strix firmware.
  /// Returns a Map with 'easting', 'northing', and 'zone'.
  static Map<String, dynamic> latLonToUTM(double lat, double lon) {
    final utm = UTM.fromLatLon(lat: lat, lon: lon);

    // The `utm` package already computes the correct UTM latitude band letter
    // (e.g. "19H" for Santiago, Chile) using the same band logic as the
    // firmware's portal.h: zoneLetters[(lat + 80) >> 3] over 'CDEFGHJKLMNPQRSTUVWXX'.
    // `utm.zone` returns "<zoneNumber><zoneLetter>", e.g. "19H".
    return {
      'utmEaste': utm.easting.round(),
      'utmNorte': utm.northing.round(),
      'utmZone': utm.zone,
    };
  }
}
