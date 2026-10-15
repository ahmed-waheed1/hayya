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

  group('minute adjustments', () {
    test('move each time by exactly its minutes, and nothing else', () {
      final plain = times(cairo);
      final adjusted = times(
        cairo,
        const PrayerCalculationSettings()
            .withAdjustment(Prayer.fajr, 5)
            .withAdjustment(Prayer.sunrise, -2)
            .withAdjustment(Prayer.maghrib, 30)
            .withAdjustment(Prayer.isha, -30),
      );
      Duration moved(Prayer p) => adjusted[p].time.difference(plain[p].time);

      expect(moved(Prayer.fajr), const Duration(minutes: 5));
      expect(moved(Prayer.sunrise), const Duration(minutes: -2));
      expect(moved(Prayer.dhuhr), Duration.zero);
      expect(moved(Prayer.asr), Duration.zero);
      expect(moved(Prayer.maghrib), const Duration(minutes: 30));
      expect(moved(Prayer.isha), const Duration(minutes: -30));
    });

    test('add to a method\'s own adjustments (Dubai: Dhuhr +3)', () {
      const dubai = PrayerCalculationSettings(method: CalculationMethod.dubai);
      final plain = times(makkah, dubai);
      final adjusted = times(makkah, dubai.withAdjustment(Prayer.dhuhr, 2));
      expect(
        adjusted[Prayer.dhuhr].time.difference(plain[Prayer.dhuhr].time),
        const Duration(minutes: 2),
      );
    });

    test('are clamped to ±30 and zero entries are dropped', () {
      const base = PrayerCalculationSettings();
      expect(base.withAdjustment(Prayer.asr, 45).adjustmentFor(Prayer.asr), 30);
      expect(
        base.withAdjustment(Prayer.asr, -99).adjustmentFor(Prayer.asr),
        -30,
      );
      // Back to zero compares equal to never adjusted.
      expect(
        base.withAdjustment(Prayer.asr, 4).withAdjustment(Prayer.asr, 0),
        base,
      );
    });
  });

  group('high-latitude rule', () {
    const oslo = GeoCoordinates(59.9139, 10.7522);
    final midsummer = DateTime(2026, 6, 21);

    PrayerDay osloOn(HighLatitudeRule rule) => repository.timesFor(
      midsummer,
      oslo,
      PrayerCalculationSettings(
        method: CalculationMethod.muslimWorldLeague,
        highLatitudeRule: rule,
      ),
    );

    test('decides Fajr and Isha where twilight never ends', () {
      final middle = osloOn(HighLatitudeRule.middleOfTheNight);
      final seventh = osloOn(HighLatitudeRule.seventhOfTheNight);
      final angle = osloOn(HighLatitudeRule.twilightAngle);

      expect(seventh[Prayer.fajr].time, isNot(middle[Prayer.fajr].time));
      expect(seventh[Prayer.isha].time, isNot(middle[Prayer.isha].time));
      expect(angle[Prayer.fajr].time, isNot(middle[Prayer.fajr].time));
      // The rule only bounds Fajr and Isha.
      for (final p in [Prayer.sunrise, Prayer.dhuhr, Prayer.maghrib]) {
        expect(seventh[p].time, middle[p].time, reason: p.name);
      }
    });

    test('makes no difference in Cairo', () {
      final middle = times(cairo);
      final angle = times(
        cairo,
        const PrayerCalculationSettings(
          highLatitudeRule: HighLatitudeRule.twilightAngle,
        ),
      );
      expect(angle.times, middle.times);
    });
  });
}
