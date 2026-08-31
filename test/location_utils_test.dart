import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/location_utils.dart';

void main() {
  group('LocationUtils.latLonToUTM', () {
    test('Santiago, Chile (lat -33.45, lon -70.66) -> zone 19H', () {
      final result = LocationUtils.latLonToUTM(-33.45, -70.66);

      expect(result['utmZone'], '19H');
      expect(result['utmEaste'], 345713);
      expect(result['utmNorte'], 6297592);
    });

    test('Origin (lat 0.0, lon 0.0) -> zone 31N', () {
      final result = LocationUtils.latLonToUTM(0.0, 0.0);

      expect(result['utmZone'], '31N');
      expect(result['utmEaste'], 166021);
      expect(result['utmNorte'], 0);
    });
  });
}
