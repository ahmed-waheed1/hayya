import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/data/hijri_calendar_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/hijri_date.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_hijri_date.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:hayya/features/timetable/domain/entities/timetable_month.dart';
import 'package:hayya/features/timetable/domain/usecases/get_month_timetable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_location_service.dart';

void main() {
  const repository = AdhanPrayerTimesRepository();
  late HijriCalendarRepositoryImpl hijri;
  late GetMonthTimetable getTimetable;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    hijri = HijriCalendarRepositoryImpl(await SharedPreferences.getInstance());
    getTimetable = GetMonthTimetable(repository, hijri);
  });

  TimetableMonth monthOf(
    int year,
    int month, {
    PrayerCalculationSettings settings = const PrayerCalculationSettings(),
  }) => getTimetable(
    CalendarMonth(year, month),
    coordinates: cairo.coordinates,
    settings: settings,
  );

  group('CalendarMonth', () {
    test('steps across year boundaries', () {
      expect(const CalendarMonth(2026, 12).next, const CalendarMonth(2027, 1));
      expect(
        const CalendarMonth(2027, 1).previous,
        const CalendarMonth(2026, 12),
      );
      expect(const CalendarMonth(2026, 1).shift(-13), CalendarMonth(2024, 12));
      expect(const CalendarMonth(2026, 11).shift(14), CalendarMonth(2028, 1));
    });

    test('knows month lengths, leap Februaries included', () {
      expect(const CalendarMonth(2026, 2).length, 28);
      expect(const CalendarMonth(2028, 2).length, 29);
      expect(const CalendarMonth(2100, 2).length, 28);
      expect(const CalendarMonth(2026, 10).length, 31);
      expect(const CalendarMonth(2026, 11).length, 30);
    });
  });

  group('matches the single-day calculation Home uses', () {
    void expectMatchesHome(
      TimetableMonth table,
      PrayerCalculationSettings settings,
    ) {
      final getSchedule = GetPrayerSchedule(repository);
      final getHijri = GetHijriDate(hijri);
      for (final day in table.days) {
        final noon = day.date.add(const Duration(hours: 12));
        final home = getSchedule(
          now: noon,
          coordinates: cairo.coordinates,
          settings: settings,
        );
        expect(day.times, home.today, reason: '${day.date}');
        expect(day.hijri, getHijri(day.date), reason: '${day.date}');
      }
    }

    test('with the default settings', () {
      final table = monthOf(2026, 10);
      expect(table.days, hasLength(31));
      expectMatchesHome(table, const PrayerCalculationSettings());
    });

    test('with another method, Hanafi Asr and minute adjustments', () {
      final settings = const PrayerCalculationSettings(
        method: CalculationMethod.muslimWorldLeague,
        madhab: AsrMadhab.hanafi,
      ).withAdjustment(Prayer.fajr, 3).withAdjustment(Prayer.isha, -5);
      final table = monthOf(2027, 2, settings: settings);
      expect(table.days, hasLength(28));
      expectMatchesHome(table, settings);

      final plain = monthOf(2027, 2);
      final shift = table.days.first.times[Prayer.fajr].time.difference(
        plain.days.first.times[Prayer.fajr].time,
      );
      // MWL Fajr (18°) differs from Egyptian (19.5°), plus 3 minutes.
      expect(shift, isNot(Duration.zero));
    });
  });

  group('Hijri dates', () {
    test('mark the start of Ramadan and Eid al-Fitr', () {
      final february = monthOf(2026, 2);
      expect(
        february.days[17].hijri,
        const HijriDate(year: 1447, month: 9, day: 1),
      );
      expect(february.firstHijri.month, 8); // Sha'ban
      expect(february.lastHijri.month, 9); // Ramadan

      final march = monthOf(2026, 3);
      expect(
        march.days[18].hijri,
        const HijriDate(year: 1447, month: 9, day: 30),
      );
      expect(
        march.days[19].hijri,
        const HijriDate(year: 1447, month: 10, day: 1),
      );
    });

    test('follow the user\'s adjustment', () async {
      await hijri.saveAdjustmentDays(1);
      final ahead = monthOf(2026, 2);
      expect(
        ahead.days[16].hijri,
        const HijriDate(year: 1447, month: 9, day: 1),
      );

      await hijri.saveAdjustmentDays(-1);
      final behind = monthOf(2026, 2);
      expect(
        behind.days[18].hijri,
        const HijriDate(year: 1447, month: 9, day: 1),
      );
    });

    test('cross into a new Hijri year', () {
      final june = monthOf(2026, 6);
      expect(june.firstHijri.year, 1447);
      expect(june.lastHijri.year, 1448);
      expect(
        june.days[15].hijri,
        const HijriDate(year: 1448, month: 1, day: 1),
      );
    });
  });

  // Egypt moves its clocks at midnight on 24 April 2026 (forward; local
  // midnight doesn't exist that day) and 29 October 2026 (back). These
  // checks hold in any time zone and are meaningful in any that has DST.
  group('daylight saving changes', () {
    bool nearTransition(DateTime t) {
      const hour = Duration(hours: 1);
      return t.subtract(hour).timeZoneOffset != t.timeZoneOffset ||
          t.add(hour).timeZoneOffset != t.timeZoneOffset;
    }

    for (final (year, month) in [
      (2026, 3),
      (2026, 4),
      (2026, 10),
      (2026, 11),
    ]) {
      test('$year-$month: one row per calendar day', () {
        final table = monthOf(year, month);
        expect(
          [for (final day in table.days) day.date.day],
          [for (var d = 1; d <= CalendarMonth(year, month).length; d++) d],
        );
        for (final day in table.days) {
          expect(day.date.month, month);
          expect(table.indexOf(day.date), day.date.day - 1);
        }
      });

      test('$year-$month: times move with the clock, not with the sun', () {
        final table = monthOf(year, month);
        for (var i = 1; i < table.days.length; i++) {
          for (final prayer in Prayer.values) {
            final before = table.days[i - 1].times[prayer].time;
            final after = table.days[i].times[prayer].time;
            // adhan rebuilds each time from its local fields, so a time in
            // the hour repeated when clocks go back can come out an hour
            // off. Only far-away zones put Cairo's times there.
            if (nearTransition(before) || nearTransition(after)) continue;
            // In UTC the sun moves a few minutes a day at most.
            final solar = after.toUtc().difference(
              before.toUtc().add(const Duration(days: 1)),
            );
            expect(solar.inMinutes.abs(), lessThan(4), reason: '$after');
            // On the clock, it jumps by exactly the change in UTC offset.
            // (Taken to the nearest day: Cairo's times can sit near
            // midnight when the tests run in a far-away zone.)
            final minutes =
                (after.hour * 60 + after.minute) -
                (before.hour * 60 + before.minute);
            final wallClock = Duration(minutes: (minutes + 720) % 1440 - 720);
            final offsetChange = after.timeZoneOffset - before.timeZoneOffset;
            expect(
              (wallClock - solar - offsetChange).inMinutes.abs(),
              lessThanOrEqualTo(1),
              reason: '$prayer on ${table.days[i].date}',
            );
          }
        }
      });
    }
  });
}
