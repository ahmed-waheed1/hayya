import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:hayya/features/tracker/domain/entities/tracking_position.dart';

import '../../../helpers/prayer_fixtures.dart';

void main() {
  final today = DateTime(2026, 10, 15);
  final yesterday = DateTime(2026, 10, 14);

  PrayerSchedule at(int h, int m) => PrayerSchedule.resolve(
    now: DateTime(2026, 10, 15, h, m),
    yesterday: fixedDay(yesterday),
    today: fixedDay(today),
    tomorrow: fixedDay(DateTime(2026, 10, 16)),
  );

  group('TrackingPosition', () {
    test('after midnight and before Fajr it is still yesterday', () {
      expect(
        TrackingPosition.of(at(0, 30)),
        TrackingPosition(day: yesterday, due: 5),
      );
    });

    test('from Fajr it is today, with the prayers that have begun', () {
      expect(
        TrackingPosition.of(at(5, 0)),
        TrackingPosition(day: today, due: 1),
      );
      expect(
        TrackingPosition.of(at(13, 0)),
        TrackingPosition(day: today, due: 2),
      );
      expect(
        TrackingPosition.of(at(23, 59)),
        TrackingPosition(day: today, due: 5),
      );
    });
  });

  group('prayerSlots', () {
    test('only prayers that have begun are open', () {
      final slots = prayerSlots(at(16, 0));
      expect(slots.keys, [
        Prayer.fajr,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]);
      expect(slots.values.map((s) => s.day), everyElement(today));
      expect(
        {for (final s in slots.values) s.prayer: s.open},
        {
          Prayer.fajr: true,
          Prayer.dhuhr: true,
          Prayer.asr: true,
          Prayer.maghrib: false,
          Prayer.isha: false,
        },
      );
    });

    test('a prayer opens exactly at its time', () {
      expect(prayerSlots(at(17, 59))[Prayer.maghrib]!.open, isFalse);
      expect(prayerSlots(at(18, 0))[Prayer.maghrib]!.open, isTrue);
    });

    test('Sunrise is not a slot', () {
      expect(prayerSlots(at(12, 0)).containsKey(Prayer.sunrise), isFalse);
    });

    test('after midnight, Isha records to yesterday and stays open', () {
      final slots = prayerSlots(at(0, 30));
      expect(
        slots[Prayer.isha],
        PrayerSlot(prayer: Prayer.isha, day: yesterday, open: true),
      );
      for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib]) {
        expect(slots[p], PrayerSlot(prayer: p, day: today, open: false));
      }
    });

    test("from Fajr, Isha is today's again and closed until its time", () {
      expect(
        prayerSlots(at(5, 0))[Prayer.isha],
        PrayerSlot(prayer: Prayer.isha, day: today, open: false),
      );
    });
  });
}
