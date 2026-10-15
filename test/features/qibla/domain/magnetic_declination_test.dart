import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/qibla/domain/magnetic_declination.dart';
import 'package:hayya/features/qibla/domain/wmm2025_coefficients.dart';

import '../fixtures/wmm2025_test_values.dart';

void main() {
  group('NOAA calculator (WMM-2025, sea level)', () {
    // Values from https://www.ngdc.noaa.gov/geomag/calculators/magcalc.shtml
    // (its calculateDeclination API), queried 2026-10-15.
    const cairo = GeoCoordinates(30.0444, 31.2357);
    const newYork = GeoCoordinates(40.7128, -74.0060);
    const jakarta = GeoCoordinates(-6.2088, 106.8456);
    const london = GeoCoordinates(51.5074, -0.1278);

    for (final (date, cities) in [
      (
        DateTime(2026, 10, 15),
        [
          ('Cairo', cairo, 4.77114),
          ('New York', newYork, -12.46302),
          ('Jakarta', jakarta, 0.64986),
          ('London', london, 1.21094),
        ],
      ),
      (
        DateTime(2029, 7, 1),
        [
          ('Cairo', cairo, 4.83876),
          ('New York', newYork, -12.35605),
          ('Jakarta', jakarta, 0.71295),
          ('London', london, 1.67271),
        ],
      ),
    ]) {
      for (final (name, at, expected) in cities) {
        test('$name on ${date.toIso8601String().substring(0, 10)} '
            'is $expected°', () {
          expect(magneticDeclination(at, date), closeTo(expected, 1e-4));
        });
      }
    }
  });

  test('matches all ${wmm2025TestValues.length} WMM2025 test values', () {
    for (final (year, altitude, lat, lng, expected) in wmm2025TestValues) {
      expect(
        declinationAt(
          latitude: lat,
          longitude: lng,
          decimalYear: year,
          altitudeKm: altitude,
        ),
        // The published values are rounded to 0.01°.
        closeTo(expected, 0.0051),
        reason: '$year, $altitude km, $lat, $lng',
      );
    }
  });

  group('decimalYear', () {
    test('counts whole days, as NOAA does', () {
      expect(decimalYear(DateTime(2026, 10, 15)), closeTo(2026.7863, 1e-4));
      expect(decimalYear(DateTime(2029, 7, 1)), closeTo(2029.4958, 1e-4));
      expect(
        decimalYear(DateTime(2026, 10, 15, 23, 59)),
        closeTo(2026.7863, 1e-4),
      );
      expect(decimalYear(DateTime(2025)), 2025.0);
    });

    test('leap years have 366 days', () {
      expect(
        decimalYear(DateTime(2028, 12, 31)),
        closeTo(2028 + 365 / 366, 1e-9),
      );
    });
  });

  test('the model covers 2025–2030', () {
    expect(wmmEpoch, 2025.0);
    expect(wmmValidUntil, 2030.0);
  });
}
