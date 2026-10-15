import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/tracker/domain/entities/calendar_day.dart';
import 'package:hayya/features/tracker/domain/entities/tracker_data.dart';
import 'package:hayya/features/tracker/domain/entities/tracker_stats.dart';
import 'package:hayya/features/tracker/domain/entities/tracking_position.dart';

final today = DateTime(2026, 10, 15);
const all = {...trackedPrayers};

DateTime ago(int days) => today.addDays(-days);

/// [days] keyed by days ago.
TrackerData dataOf(Map<int, Set<Prayer>> days, {DateTime? since}) =>
    TrackerData(
      since: since ?? ago(60),
      days: {
        for (final MapEntry(:key, :value) in days.entries) ago(key): value,
      },
    );

TrackerStats statsOf(TrackerData data, {DateTime? day, int? due}) =>
    TrackerStats.compute(data, TrackingPosition(day: day ?? today, due: due));

void main() {
  group('streak', () {
    test('is zero with no data', () {
      expect(statsOf(dataOf({})).streak, 0);
    });

    test('counts complete days back to the first gap', () {
      final data = dataOf({
        1: all,
        2: all,
        3: all,
        4: {Prayer.fajr},
        5: all,
      });
      expect(statsOf(data).streak, 3);
    });

    test('includes today once all five are prayed', () {
      final data = dataOf({0: all, 1: all});
      expect(statsOf(data).streak, 2);
    });

    test('an unfinished today does not break it', () {
      final data = dataOf({
        0: {Prayer.fajr},
        1: all,
        2: all,
      });
      expect(statsOf(data).streak, 2);
    });

    test('a day with no data after tracking began breaks it', () {
      final data = dataOf({1: all, 3: all});
      expect(statsOf(data).streak, 1);
    });

    test('stops at the install day instead of counting further back', () {
      final data = dataOf({0: all, 1: all, 2: all}, since: ago(2));
      expect(statsOf(data).streak, 3);
    });

    test('runs through days before install the user filled in', () {
      final data = dataOf({0: all, 1: all, 2: all, 3: all}, since: ago(1));
      expect(statsOf(data).streak, 4);
    });

    test('is zero when yesterday was missed and today is unfinished', () {
      final data = dataOf({
        0: {Prayer.fajr, Prayer.dhuhr},
        2: all,
      });
      expect(statsOf(data).streak, 0);
    });
  });

  group('last 7 days', () {
    test('a brand-new user with nothing due has no percentage', () {
      final stats = statsOf(dataOf({}, since: today), due: 0);
      expect(stats.weekPercent, isNull);
      expect(stats.weekPossible, 0);
    });

    test('a new user is measured only from the install day', () {
      // Installed two days ago: 3 days count, not 7.
      final data = dataOf({
        0: all,
        1: all,
        2: {Prayer.fajr},
      }, since: ago(2));
      final stats = statsOf(data, due: 5);
      expect(stats.weekPrayed, 11);
      expect(stats.weekPossible, 15);
      expect(stats.weekPercent, 73);
    });

    test('days with no data after install count as zero', () {
      final data = dataOf({1: all}, since: ago(30));
      final stats = statsOf(data, due: 5);
      expect(stats.weekPrayed, 5);
      expect(stats.weekPossible, 35);
      expect(stats.weekPercent, 14);
    });

    test("today counts only the prayers that have begun", () {
      // 10:00: only Fajr is due today.
      final data = dataOf({
        0: {Prayer.fajr},
        1: all,
      }, since: ago(1));
      final stats = statsOf(data, due: 1);
      expect(stats.weekPrayed, 6);
      expect(stats.weekPossible, 6);
      expect(stats.weekPercent, 100);
    });

    test('without prayer times, today counts only what is marked', () {
      final data = dataOf({
        0: {Prayer.fajr, Prayer.dhuhr},
      }, since: today);
      final stats = statsOf(data);
      expect(stats.weekPrayed, 2);
      expect(stats.weekPossible, 2);
    });

    test('rounds to the nearest percent', () {
      // 31 / 35, as in the design.
      final data = dataOf({
        0: all,
        1: all,
        2: all,
        3: all,
        4: all,
        5: {Prayer.fajr, Prayer.dhuhr, Prayer.asr},
        6: {Prayer.fajr, Prayer.dhuhr, Prayer.asr},
      });
      expect(statsOf(data, due: 5).weekPercent, 89);
    });

    test('ignores days older than seven', () {
      final data = dataOf({7: all, 8: all}, since: ago(10));
      expect(statsOf(data, due: 0).weekPrayed, 0);
    });
  });

  group('missed by prayer', () {
    test('a new user has nothing missed and no known days', () {
      final stats = statsOf(dataOf({}, since: today));
      expect(stats.missedDays, 0);
      expect(stats.missed.values, everyElement(0));
      expect(stats.mostMissed, isEmpty);
    });

    test('counts unmarked prayers on known past days', () {
      final data = dataOf({
        1: {Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha},
        2: {Prayer.dhuhr, Prayer.asr, Prayer.maghrib},
      }, since: ago(2));
      final stats = statsOf(data);
      expect(stats.missedDays, 2);
      expect(stats.missed, {
        Prayer.fajr: 2,
        Prayer.dhuhr: 0,
        Prayer.asr: 0,
        Prayer.maghrib: 0,
        Prayer.isha: 1,
      });
      expect(stats.mostMissed, [Prayer.fajr]);
    });

    test('today is never counted as missed', () {
      final stats = statsOf(dataOf({}, since: today), due: 5);
      expect(stats.missed.values, everyElement(0));
    });

    test('days before install are not missed', () {
      final stats = statsOf(dataOf({}, since: ago(3)));
      expect(stats.missedDays, 3);
      expect(stats.missed[Prayer.fajr], 3);
    });

    test('looks back 30 days', () {
      final stats = statsOf(dataOf({}, since: ago(100)));
      expect(stats.missedDays, 30);
      expect(stats.missed[Prayer.isha], 30);
    });

    test('ties are all most missed', () {
      final data = dataOf({
        1: {Prayer.dhuhr, Prayer.asr, Prayer.maghrib},
      }, since: ago(1));
      expect(statsOf(data).mostMissed, [Prayer.fajr, Prayer.isha]);
    });
  });

  group('around midnight', () {
    // Prayer day 14 October: it is 00:30 on the 15th, before Fajr.
    final lastNight = ago(1);

    test('Isha ticked after midnight completes the day it belongs to', () {
      final data = dataOf({1: all, 2: all}, since: ago(2));
      final stats = statsOf(data, day: lastNight, due: 5);
      expect(stats.streak, 2);
      expect(stats.weekPercent, 100);
    });

    test('Isha not ticked yet keeps the streak from the day before', () {
      final data = dataOf({
        1: all.difference({Prayer.isha}),
        2: all,
      });
      final stats = statsOf(data, day: lastNight, due: 5);
      expect(stats.streak, 1);
    });

    test('nothing counts against the calendar day that has just begun', () {
      final data = dataOf({1: all}, since: ago(1));
      final stats = statsOf(data, day: lastNight, due: 5);
      expect(stats.missedDays, 0);
      expect(stats.weekPossible, 5);
    });
  });

  test('stays correct across a daylight-saving change', () {
    // Europe and North America change clocks in late October/March; the
    // days must still step one calendar day at a time.
    final day = DateTime(2026, 3, 30);
    final data = TrackerData(
      since: DateTime(2026, 3, 1),
      days: {for (var i = 0; i < 5; i++) day.addDays(-i): all},
    );
    final stats = TrackerStats.compute(
      data,
      TrackingPosition(day: day, due: 5),
    );
    expect(stats.streak, 5);
  });
}
