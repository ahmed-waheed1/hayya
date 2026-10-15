import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:hayya/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_prayer_schedule.dart';

import '../../../helpers/prayer_fixtures.dart';

class _CountingRepository implements PrayerTimesRepository {
  final calls = <(DateTime, GeoCoordinates, PrayerCalculationSettings)>[];

  @override
  PrayerDay timesFor(
    DateTime date,
    GeoCoordinates coordinates,
    PrayerCalculationSettings settings,
  ) {
    calls.add((date, coordinates, settings));
    return fixedDay(date);
  }
}

void main() {
  const cairo = GeoCoordinates(30.0444, 31.2357);
  const egyptian = PrayerCalculationSettings();
  late _CountingRepository repository;
  late GetPrayerSchedule getSchedule;

  setUp(() {
    repository = _CountingRepository();
    getSchedule = GetPrayerSchedule(repository);
  });

  test('calculates yesterday, today and tomorrow', () {
    final s = getSchedule(
      now: DateTime(2026, 10, 15, 21),
      coordinates: cairo,
      settings: egyptian,
    );
    expect(repository.calls.map((c) => c.$1), [
      DateTime(2026, 10, 14),
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 16),
    ]);
    expect(s.current.prayer, Prayer.isha);
    expect(s.next.time, DateTime(2026, 10, 16, 5));
  });

  test('reuses the days while only the time changes', () {
    for (var second = 0; second < 60; second++) {
      getSchedule(
        now: DateTime(2026, 10, 15, 12, 0, second),
        coordinates: cairo,
        settings: egyptian,
      );
    }
    expect(repository.calls, hasLength(3));
  });

  test('after midnight, only the new tomorrow is calculated', () {
    getSchedule(
      now: DateTime(2026, 10, 15, 23, 59),
      coordinates: cairo,
      settings: egyptian,
    );
    final s = getSchedule(
      now: DateTime(2026, 10, 16, 0, 1),
      coordinates: cairo,
      settings: egyptian,
    );
    expect(repository.calls.map((c) => c.$1).skip(3), [DateTime(2026, 10, 17)]);
    expect(s.today.date, DateTime(2026, 10, 16));
    expect(s.current.time, DateTime(2026, 10, 15, 19, 30));
  });

  test('recalculates when the place or settings change', () {
    final now = DateTime(2026, 10, 15, 12);
    getSchedule(now: now, coordinates: cairo, settings: egyptian);
    getSchedule(
      now: now,
      coordinates: cairo,
      settings: egyptian.copyWith(madhab: AsrMadhab.hanafi),
    );
    getSchedule(
      now: now,
      coordinates: const GeoCoordinates(21.4225, 39.8262),
      settings: egyptian,
    );
    expect(repository.calls, hasLength(9));
    expect(repository.calls[3].$3.madhab, AsrMadhab.hanafi);
    expect(repository.calls[6].$2.latitude, 21.4225);
  });
}
