import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_schedule.dart';

import '../../../helpers/prayer_fixtures.dart';

void main() {
  final today = DateTime(2026, 10, 15);
  final yesterday = fixedDay(DateTime(2026, 10, 14));
  final tomorrow = fixedDay(DateTime(2026, 10, 16));

  PrayerSchedule at(int h, int m, [int s = 0]) => PrayerSchedule.resolve(
    now: DateTime(2026, 10, 15, h, m, s),
    yesterday: yesterday,
    today: fixedDay(today),
    tomorrow: tomorrow,
  );

  group('current and next prayer', () {
    final cases = <(String, PrayerSchedule, Prayer, Prayer)>[
      ('just after midnight', at(0, 30), Prayer.isha, Prayer.fajr),
      ('one second before Fajr', at(4, 59, 59), Prayer.isha, Prayer.fajr),
      ('exactly at Fajr', at(5, 0), Prayer.fajr, Prayer.sunrise),
      ('after sunrise', at(9, 0), Prayer.sunrise, Prayer.dhuhr),
      ('exactly at Dhuhr', at(12, 0), Prayer.dhuhr, Prayer.asr),
      ('during Asr', at(16, 0), Prayer.asr, Prayer.maghrib),
      ('during Maghrib', at(18, 45), Prayer.maghrib, Prayer.isha),
      ('exactly at Isha', at(19, 30), Prayer.isha, Prayer.fajr),
      ('before midnight', at(23, 59, 59), Prayer.isha, Prayer.fajr),
    ];
    for (final (label, schedule, current, next) in cases) {
      test(label, () {
        expect(schedule.current.prayer, current);
        expect(schedule.next.prayer, next);
      });
    }
  });

  test('before Fajr, the current Isha is yesterday\'s', () {
    final s = at(2, 0);
    expect(s.current, yesterday[Prayer.isha]);
    expect(s.next.time, DateTime(2026, 10, 15, 5));
    expect(s.nextIsTomorrow, isFalse);
  });

  test('after Isha, the next Fajr is tomorrow\'s', () {
    final s = at(21, 0);
    expect(s.current.time, DateTime(2026, 10, 15, 19, 30));
    expect(s.next, tomorrow[Prayer.fajr]);
    expect(s.nextIsTomorrow, isTrue);
  });

  test('today is always the day of now, even after Isha', () {
    expect(at(21, 0).today.date, today);
    expect(at(2, 0).today.date, today);
  });

  group('remaining and progress', () {
    test('mid-interval', () {
      // Asr 15:30 → Maghrib 18:00 is 150 min; at 16:00, 30 min have passed.
      final s = at(16, 0);
      expect(s.remaining, const Duration(hours: 2));
      expect(s.progress, closeTo(30 / 150, 1e-9));
    });

    test('across midnight', () {
      // Isha 19:30 yesterday → Fajr 05:00 is 570 min; at 02:00, 390 passed.
      final s = at(2, 0);
      expect(s.remaining, const Duration(hours: 3));
      expect(s.progress, closeTo(390 / 570, 1e-9));
    });

    test('starts at 0 the moment a prayer begins', () {
      final s = at(12, 0);
      expect(s.progress, 0);
      expect(s.remaining, const Duration(hours: 3, minutes: 30));
    });

    test('seconds count', () {
      expect(at(17, 59, 59).remaining, const Duration(seconds: 1));
    });
  });

  test('times are listed in prayer order', () {
    final day = fixedDay(today);
    expect(day.times.map((t) => t.prayer), Prayer.values);
    expect(day[Prayer.asr].time, DateTime(2026, 10, 15, 15, 30));
  });

  test('only Sunrise is not obligatory', () {
    expect(Prayer.values.where((p) => !p.isObligatory), [Prayer.sunrise]);
  });
}
