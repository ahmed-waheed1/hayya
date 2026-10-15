import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/qibla/domain/heading_math.dart';
import 'package:hayya/features/qibla/domain/qibla_direction.dart';

/// Reference values from an independent spherical computation (bearing by
/// the forward-azimuth formula, distance by haversine with R = 6371.0088).
void main() {
  const cairo = GeoCoordinates(30.0444, 31.2357);
  const jakarta = GeoCoordinates(-6.2088, 106.8456);
  const london = GeoCoordinates(51.5074, -0.1278);
  const newYork = GeoCoordinates(40.7128, -74.0060);

  /// ~1.1 km due north of the Kaaba, inside Makkah.
  const northOfKaaba = GeoCoordinates(21.4325, 39.8261818);

  /// Masjid Aisha (Tan'eem), ~14 km north-west of the Kaaba.
  const masjidAisha = GeoCoordinates(21.4766, 39.7027);

  group('Qibla bearing', () {
    for (final (name, at, bearing, point) in [
      ('Cairo', cairo, 136.137, CompassPoint.se),
      ('Jakarta', jakarta, 295.152, CompassPoint.nw),
      ('London', london, 118.987, CompassPoint.se),
      ('New York', newYork, 58.482, CompassPoint.ne),
      ('north of the Kaaba', northOfKaaba, 180.0, CompassPoint.s),
      ('Masjid Aisha', masjidAisha, 115.175, CompassPoint.se),
    ]) {
      test('$name is $bearing° ($point)', () {
        final actual = qiblaBearing(at);
        expect(actual, closeTo(bearing, 0.01));
        expect(compassPoint(actual), point);
      });
    }

    test('comes from adhan\'s Qibla', () {
      expect(
        qiblaBearing(cairo),
        adhan.Qibla(adhan.Coordinates(cairo.latitude, cairo.longitude))
            .direction,
      );
    });

    test('always lies in 0–360', () {
      for (var lng = -180.0; lng <= 180; lng += 15) {
        for (var lat = -80.0; lat <= 80; lat += 20) {
          final b = qiblaBearing(GeoCoordinates(lat, lng));
          expect(b, inInclusiveRange(0, 360), reason: '$lat, $lng');
        }
      }
    });

    test('points each way around the Kaaba', () {
      // Compared as turns, so 359.9° counts as next to 0°.
      void expectFacing(GeoCoordinates at, double expected) => expect(
        shortestTurn(qiblaBearing(at), expected).abs(),
        lessThan(0.5),
        reason: '$at',
      );
      expectFacing(const GeoCoordinates(21.4125, 39.8262), 0); // south
      expectFacing(const GeoCoordinates(21.4225, 39.8162), 90); // west
      expectFacing(const GeoCoordinates(21.4225, 39.8362), 270); // east
    });
  });

  group('distance to the Kaaba', () {
    for (final (name, at, km) in [
      ('Cairo', cairo, 1287.215),
      ('Jakarta', jakarta, 7920.140),
      ('London', london, 4793.778),
      ('New York', newYork, 10306.317),
      ('north of the Kaaba', northOfKaaba, 1.109),
      ('Masjid Aisha', masjidAisha, 14.124),
    ]) {
      test('$name is $km km', () {
        expect(distanceToKaabaKm(at), closeTo(km, 0.01));
      });
    }

    test('is zero at the Kaaba', () {
      expect(distanceToKaabaKm(kaaba), 0);
    });
  });

  test('compass points wrap at north', () {
    expect(compassPoint(359), CompassPoint.n);
    expect(compassPoint(22.4), CompassPoint.n);
    expect(compassPoint(22.6), CompassPoint.ne);
    expect(compassPoint(270), CompassPoint.w);
    expect(compassPoint(-10), CompassPoint.n);
  });
}
