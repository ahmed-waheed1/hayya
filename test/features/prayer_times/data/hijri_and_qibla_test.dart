import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/prayer_times/data/hijri_calendar_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/hijri_date.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_hijri_date.dart';
import 'package:hayya/features/qibla/domain/qibla_direction.dart';

void main() {
  group('Hijri date (Umm al-Qura)', () {
    const getHijriDate = GetHijriDate(HijriCalendarRepositoryImpl());

    test('1 Ramadan 1447 is 18 February 2026', () {
      expect(
        getHijriDate(DateTime(2026, 2, 18)),
        const HijriDate(year: 1447, month: 9, day: 1),
      );
    });

    test('15 October 2026', () {
      expect(
        getHijriDate(DateTime(2026, 10, 15)),
        const HijriDate(year: 1448, month: 5, day: 4),
      );
    });

    test('the time of day does not change the date', () {
      expect(
        getHijriDate(DateTime(2026, 10, 15, 23, 59)),
        getHijriDate(DateTime(2026, 10, 15)),
      );
    });
  });

  group('Qibla bearing', () {
    test('Cairo is about 136° (SE)', () {
      final bearing = qiblaBearing(const GeoCoordinates(30.0444, 31.2357));
      expect(bearing, closeTo(136.1, 0.5));
      expect(compassPoint(bearing), CompassPoint.se);
    });

    test('London is about 119° (SE)', () {
      final bearing = qiblaBearing(const GeoCoordinates(51.5074, -0.1278));
      expect(bearing, closeTo(118.99, 0.5));
    });

    test('compass points wrap at north', () {
      expect(compassPoint(359), CompassPoint.n);
      expect(compassPoint(22.4), CompassPoint.n);
      expect(compassPoint(22.6), CompassPoint.ne);
      expect(compassPoint(270), CompassPoint.w);
    });
  });
}
