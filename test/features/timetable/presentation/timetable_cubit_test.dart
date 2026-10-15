import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/data/hijri_calendar_repository_impl.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/timetable/domain/entities/timetable_month.dart';
import 'package:hayya/features/timetable/domain/usecases/get_month_timetable.dart';
import 'package:hayya/features/timetable/presentation/cubit/timetable_cubit.dart';
import 'package:hayya/features/timetable/presentation/cubit/timetable_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_location_service.dart';

void main() {
  late PrayerSettingsRepositoryImpl settings;
  late HijriCalendarRepositoryImpl hijri;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = PrayerSettingsRepositoryImpl(prefs);
    hijri = HijriCalendarRepositoryImpl(prefs);
  });

  TimetableCubit cubitAt(
    DateTime Function() clock, {
    FakeLocationService? location,
  }) {
    final cubit = TimetableCubit(
      locationService: location ?? FakeLocationService(lastKnown: cairo),
      settingsRepository: settings,
      hijriCalendar: hijri,
      getTimetable: GetMonthTimetable(
        const AdhanPrayerTimesRepository(),
        hijri,
      ),
      clock: clock,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  TimetableReady ready(TimetableCubit cubit) => cubit.state as TimetableReady;

  test('opens on the current month with today marked', () {
    final cubit = cubitAt(() => DateTime(2026, 10, 15, 21, 30))..start();
    final state = ready(cubit);
    expect(state.month, const CalendarMonth(2026, 10));
    expect(state.today, DateTime(2026, 10, 15));
    expect(state.todayIndex, 14);
    expect(state.timetable.days, hasLength(31));
  });

  test('steps forward from December into January', () {
    final cubit = cubitAt(() => DateTime(2026, 12, 31, 23, 59))..start();
    expect(ready(cubit).todayIndex, 30);

    cubit.showNextMonth();
    final january = ready(cubit);
    expect(january.month, const CalendarMonth(2027, 1));
    expect(january.timetable.days.first.date, DateTime(2027, 1, 1));
    expect(january.todayIndex, isNull);

    cubit.showPreviousMonth();
    expect(ready(cubit).month, const CalendarMonth(2026, 12));
    expect(ready(cubit).todayIndex, 30);
  });

  test('steps back from January into December', () {
    final cubit = cubitAt(() => DateTime(2027, 1, 1, 0, 5))..start();
    cubit.showPreviousMonth();
    final december = ready(cubit);
    expect(december.month, const CalendarMonth(2026, 12));
    expect(december.timetable.days.last.date, DateTime(2026, 12, 31));
    expect(december.todayIndex, isNull);

    cubit
      ..showPreviousMonth()
      ..showCurrentMonth();
    expect(ready(cubit).month, const CalendarMonth(2027, 1));
    expect(ready(cubit).todayIndex, 0);
  });

  test(
    'recalculates when the settings or the Hijri adjustment change',
    () async {
      final cubit = cubitAt(() => DateTime(2026, 2, 10))..start();
      final before = ready(cubit).timetable;
      expect(before.days[17].hijri.day, 1); // 1 Ramadan on 18 February

      await settings.save(
        const PrayerCalculationSettings().withAdjustment(Prayer.fajr, 10),
      );
      await Future<void>.delayed(Duration.zero);
      final adjusted = ready(cubit).timetable;
      expect(
        adjusted.days.first.times[Prayer.fajr].time.difference(
          before.days.first.times[Prayer.fajr].time,
        ),
        const Duration(minutes: 10),
      );

      await hijri.saveAdjustmentDays(1);
      await Future<void>.delayed(Duration.zero);
      expect(ready(cubit).timetable.days[16].hijri.day, 1);
    },
  );

  test('follows a new location', () async {
    final location = FakeLocationService(lastKnown: cairo);
    final cubit = cubitAt(() => DateTime(2026, 10, 15), location: location)
      ..start();
    await location.useManualLocation(alexandria);
    expect(ready(cubit).location, alexandria);
  });

  test('waits for a location when none is known', () async {
    final location = FakeLocationService();
    final cubit = cubitAt(() => DateTime(2026, 10, 15), location: location)
      ..start();
    expect(cubit.state, isA<TimetableNoLocation>());

    await location.locateDevice();
    expect(ready(cubit).location, cairo);
  });

  test('moves the highlight to the new day after midnight', () {
    var now = DateTime(2026, 10, 31, 23, 50);
    final cubit = cubitAt(() => now)..start();
    expect(ready(cubit).todayIndex, 30);

    now = DateTime(2026, 11, 1, 0, 10);
    cubit.refreshToday();
    // Still showing October, which no longer holds today.
    expect(ready(cubit).month, const CalendarMonth(2026, 10));
    expect(ready(cubit).todayIndex, isNull);
    expect(ready(cubit).today, DateTime(2026, 11, 1));
  });
}
