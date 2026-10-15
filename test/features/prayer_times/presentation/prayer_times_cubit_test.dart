import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/data/hijri_calendar_repository_impl.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_hijri_date.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:hayya/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:hayya/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_location_service.dart';

void main() {
  final makkah = UserLocation(
    coordinates: const GeoCoordinates(21.4225, 39.8262),
    updatedAt: DateTime(2026, 10, 15, 12),
  );
  final now = DateTime(2026, 10, 15, 12, 30);

  late FakeLocationService location;
  late PrayerSettingsRepositoryImpl settings;
  late HijriCalendarRepositoryImpl hijri;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = PrayerSettingsRepositoryImpl(prefs);
    hijri = HijriCalendarRepositoryImpl(prefs);
  });

  PrayerTimesCubit cubitWith(FakeLocationService fake) {
    location = fake;
    final cubit = PrayerTimesCubit(
      locationService: fake,
      settingsRepository: settings,
      getSchedule: GetPrayerSchedule(const AdhanPrayerTimesRepository()),
      getHijriDate: GetHijriDate(hijri),
      hijriCalendar: hijri,
      clock: () => now,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('a cached location shows times at once, then refreshes', () async {
    final cubit = cubitWith(
      FakeLocationService(lastKnown: cairo, results: [LocationFound(makkah)])
        ..gate = Completer(),
    );
    final started = cubit.start();

    final first = cubit.state as PrayerTimesReady;
    expect(first.location, cairo);
    expect(first.locating, isTrue);
    expect(first.schedule.today.date, DateTime(2026, 10, 15));
    expect(first.hijriDate.month, 5);
    // A background refresh never shows the permission prompt.
    expect(location.permissionRequests, [false]);

    location.gate!.complete();
    await started;
    final refreshed = cubit.state as PrayerTimesReady;
    expect(refreshed.location, makkah);
    expect(refreshed.locating, isFalse);
  });

  test('a failed background refresh keeps the cached times', () async {
    final cubit = cubitWith(
      FakeLocationService(
        lastKnown: cairo,
        results: [const LocationFailed(LocationFailure.serviceDisabled)],
      ),
    );
    await cubit.start();

    final state = cubit.state as PrayerTimesReady;
    expect(state.location, cairo);
    expect(state.locating, isFalse);
  });

  test('without a cache, loads and asks for permission', () async {
    final cubit = cubitWith(FakeLocationService()..gate = Completer());
    final started = cubit.start();

    expect(cubit.state, isA<PrayerTimesLoading>());
    expect(location.permissionRequests, [true]);

    location.gate!.complete();
    await started;
    expect((cubit.state as PrayerTimesReady).location, cairo);
  });

  test('without a cache, a failure is shown', () async {
    final cubit = cubitWith(
      FakeLocationService(
        results: [const LocationFailed(LocationFailure.permissionDenied)],
      ),
    );
    await cubit.start();

    expect(
      cubit.state,
      const PrayerTimesLocationError(LocationFailure.permissionDenied),
    );
  });

  test(
    'a refresh the user asked for shows its failure, with a way back',
    () async {
      final cubit = cubitWith(
        FakeLocationService(
          lastKnown: cairo,
          results: [
            LocationFound(cairo),
            const LocationFailed(LocationFailure.unavailable),
          ],
        ),
      );
      await cubit.start();
      await cubit.refresh();

      expect(
        cubit.state,
        PrayerTimesLocationError(LocationFailure.unavailable, lastKnown: cairo),
      );

      cubit.useLastKnown();
      expect((cubit.state as PrayerTimesReady).location, cairo);
    },
  );

  test('recheck after resume never prompts, and only runs on errors', () async {
    final cubit = cubitWith(
      FakeLocationService(
        results: [
          const LocationFailed(LocationFailure.permissionDeniedForever),
          LocationFound(cairo),
        ],
      ),
    );
    await cubit.start();
    await cubit.recheck();
    expect((cubit.state as PrayerTimesReady).location, cairo);

    await cubit.recheck();
    expect(location.permissionRequests, [true, false]);
  });

  test('settings opened for the failure', () async {
    final cubit = cubitWith(FakeLocationService());
    await cubit.openSettingsFor(LocationFailure.serviceDisabled);
    await cubit.openSettingsFor(LocationFailure.permissionDeniedForever);
    expect(location.locationSettingsOpened, 1);
    expect(location.appSettingsOpened, 1);
  });

  test('saved settings recalculate the times', () async {
    final cubit = cubitWith(FakeLocationService(lastKnown: cairo));
    await cubit.start();
    final shafi = (cubit.state as PrayerTimesReady).schedule.today;

    await settings.save(
      const PrayerCalculationSettings(madhab: AsrMadhab.hanafi),
    );
    await Future<void>.delayed(Duration.zero);

    final hanafi = (cubit.state as PrayerTimesReady).schedule.today;
    expect(hanafi[Prayer.asr].time.isAfter(shafi[Prayer.asr].time), isTrue);
    expect(hanafi[Prayer.fajr], shafi[Prayer.fajr]);
  });

  test('settings persist and default to Egyptian / Shafi\'i', () async {
    expect(settings.settings, const PrayerCalculationSettings());
    await settings.save(
      const PrayerCalculationSettings(
        method: CalculationMethod.ummAlQura,
        madhab: AsrMadhab.hanafi,
      ),
    );
    final reloaded = PrayerSettingsRepositoryImpl(
      await SharedPreferences.getInstance(),
    );
    expect(reloaded.settings.method, CalculationMethod.ummAlQura);
    expect(reloaded.settings.madhab, AsrMadhab.hanafi);
  });

  test('the cached location survives a JSON round trip', () {
    expect(UserLocation.fromJson(cairo.toJson()), cairo);
    expect(UserLocation.fromJson(alexandria.toJson()), alexandria);
    expect(UserLocation.fromJson(alexandria.toJson()).countryCode, 'EG');
  });

  test('a minute adjustment moves today\'s time', () async {
    final cubit = cubitWith(FakeLocationService(lastKnown: cairo));
    await cubit.start();
    final before = (cubit.state as PrayerTimesReady).schedule.today;

    await settings.save(
      const PrayerCalculationSettings().withAdjustment(Prayer.maghrib, -3),
    );
    await pumpEventQueue();

    final after = (cubit.state as PrayerTimesReady).schedule.today;
    expect(
      after[Prayer.maghrib].time,
      before[Prayer.maghrib].time.subtract(const Duration(minutes: 3)),
    );
    expect(after[Prayer.isha], before[Prayer.isha]);
  });

  test('a city picked elsewhere replaces the shown location', () async {
    final fake = FakeLocationService(lastKnown: cairo);
    final cubit = cubitWith(fake);
    await cubit.start();

    await fake.useManualLocation(alexandria);
    await pumpEventQueue();

    final state = cubit.state as PrayerTimesReady;
    expect(state.location, alexandria);
    // Refreshing keeps the chosen city instead of asking the device.
    final asked = fake.permissionRequests.length;
    await cubit.refresh();
    expect((cubit.state as PrayerTimesReady).location, alexandria);
    expect(fake.permissionRequests, hasLength(asked));
  });

  test('a picked city ends a location error', () async {
    final fake = FakeLocationService(
      results: [const LocationFailed(LocationFailure.permissionDenied)],
    );
    final cubit = cubitWith(fake);
    await cubit.start();
    expect(cubit.state, isA<PrayerTimesLocationError>());

    await fake.useManualLocation(alexandria);
    await pumpEventQueue();
    expect((cubit.state as PrayerTimesReady).location, alexandria);
  });

  test('the Hijri adjustment changes the shown date', () async {
    final cubit = cubitWith(FakeLocationService(lastKnown: cairo));
    await cubit.start();
    expect((cubit.state as PrayerTimesReady).hijriDate.day, 4);

    await hijri.saveAdjustmentDays(-1);
    await pumpEventQueue();
    expect((cubit.state as PrayerTimesReady).hijriDate.day, 3);
  });
}
