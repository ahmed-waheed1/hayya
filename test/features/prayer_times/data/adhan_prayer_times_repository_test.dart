import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_day.dart';

void main() {
  const repository = AdhanPrayerTimesRepository();
  const cairo = GeoCoordinates(30.0444, 31.2357);
  const makkah = GeoCoordinates(21.4225, 39.8262);
  final date = DateTime(2026, 10, 15);

  PrayerDay times(
    GeoCoordinates at, [
    PrayerCalculationSettings settings = const PrayerCalculationSettings(),
  ]) => repository.timesFor(date, at, settings);

  /// Compared in UTC so the result doesn't depend on the machine's zone.
  Matcher utcAround(int hour, int minute) => predicate<DateTime>((t) {
    final expected = DateTime.utc(2026, 10, 15, hour, minute);
    return t.toUtc().difference(expected).inMinutes.abs() <= 1;
  }, 'within a minute of $hour:$minute UTC');

  test('defaults are the Egyptian method and Shafi\'i Asr', () {
    const defaults = PrayerCalculationSettings();
    expect(defaults.method, CalculationMethod.egyptian);
    expect(defaults.madhab, AsrMadhab.shafi);
  });

  test('Cairo, 15 October 2026, Egyptian method', () {
    // Cairo is UTC+3 that day (summer time ends 29 October): Fajr 5:30,
    // Sunrise 6:57, Dhuhr 12:42, Asr 3:57, Maghrib 6:24, Isha 7:42.
    final day = times(cairo);
    expect(day[Prayer.fajr].time, utcAround(2, 30));
    expect(day[Prayer.sunrise].time, utcAround(3, 57));
    expect(day[Prayer.dhuhr].time, utcAround(9, 42));
    expect(day[Prayer.asr].time, utcAround(12, 57));
    expect(day[Prayer.maghrib].time, utcAround(15, 24));
    expect(day[Prayer.isha].time, utcAround(16, 42));
  });

  test('times are in order and on the requested day', () {
    final day = times(cairo);
    expect(day.date, date);
    for (var i = 1; i < day.times.length; i++) {
      expect(day.times[i].time.isAfter(day.times[i - 1].time), isTrue);
    }
  });

  test(
    'Egyptian angles (19.5° / 17.5°) vs Muslim World League (18° / 17°)',
    () {
      final egyptian = times(cairo);
      final mwl = times(
        cairo,
        const PrayerCalculationSettings(
          method: CalculationMethod.muslimWorldLeague,
        ),
      );
      // A deeper Fajr angle is earlier; a deeper Isha angle is later.
      expect(
        egyptian[Prayer.fajr].time.isBefore(mwl[Prayer.fajr].time),
        isTrue,
      );
      expect(egyptian[Prayer.isha].time.isAfter(mwl[Prayer.isha].time), isTrue);
      expect(egyptian[Prayer.maghrib].time, mwl[Prayer.maghrib].time);
    },
  );

  test('Hanafi Asr is later; nothing else moves', () {
    final shafi = times(cairo);
    final hanafi = times(
      cairo,
      const PrayerCalculationSettings(madhab: AsrMadhab.hanafi),
    );
    expect(
      hanafi[Prayer.asr].time.difference(shafi[Prayer.asr].time),
      greaterThan(const Duration(minutes: 30)),
    );
    for (final p in Prayer.values.where((p) => p != Prayer.asr)) {
      expect(hanafi[p].time, shafi[p].time, reason: p.name);
    }
  });

  test('Umm al-Qura puts Isha 90 minutes after Maghrib', () {
    final day = times(
      makkah,
      const PrayerCalculationSettings(method: CalculationMethod.ummAlQura),
    );
    expect(
      day[Prayer.isha].time.difference(day[Prayer.maghrib].time),
      const Duration(minutes: 90),
    );
  });

  test('every method calculates', () {
    for (final method in CalculationMethod.values) {
      final day = times(cairo, PrayerCalculationSettings(method: method));
      expect(day.times, hasLength(6), reason: method.name);
    }
  });
}
