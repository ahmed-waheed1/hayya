import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/prayer_times/data/hijri_calendar_repository_impl.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/hijri_date.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/settings/presentation/cubit/location_settings_cubit.dart';
import 'package:hayya/features/settings/presentation/cubit/prayer_settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_location_service.dart';

void main() {
  final oslo = UserLocation(
    coordinates: const GeoCoordinates(59.9139, 10.7522),
    updatedAt: DateTime(2026, 10, 15),
    countryCode: 'NO',
  );

  group('PrayerSettingsCubit', () {
    late PrayerSettingsRepositoryImpl settings;
    late HijriCalendarRepositoryImpl hijri;
    late FakeLocationService location;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = PrayerSettingsRepositoryImpl(prefs);
      hijri = HijriCalendarRepositoryImpl(prefs);
      location = FakeLocationService(lastKnown: cairo);
    });

    PrayerSettingsCubit make() {
      final cubit = PrayerSettingsCubit(
        settingsRepository: settings,
        hijriCalendar: hijri,
        locationService: location,
        clock: () => DateTime(2026, 10, 15, 13),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('each choice is saved through the repository', () async {
      final cubit = make();
      await cubit.setMethod(CalculationMethod.karachi);
      await cubit.setMadhab(AsrMadhab.hanafi);
      await cubit.setHighLatitudeRule(HighLatitudeRule.twilightAngle);

      expect(settings.settings.method, CalculationMethod.karachi);
      expect(settings.settings.madhab, AsrMadhab.hanafi);
      expect(
        settings.settings.highLatitudeRule,
        HighLatitudeRule.twilightAngle,
      );
      expect(cubit.state.settings, settings.settings);
    });

    test('steps add up and stop at ±30', () async {
      final cubit = make();
      for (var i = 0; i < 35; i++) {
        await cubit.adjust(Prayer.isha, 1);
      }
      await cubit.adjust(Prayer.fajr, -1);
      await cubit.adjust(Prayer.fajr, -1);

      expect(settings.settings.adjustmentFor(Prayer.isha), 30);
      expect(settings.settings.adjustmentFor(Prayer.fajr), -2);
    });

    test('the Hijri step stops at ±2 and previews today', () async {
      final cubit = make();
      expect(
        cubit.state.hijriToday,
        const HijriDate(year: 1448, month: 5, day: 4),
      );
      for (var i = 0; i < 4; i++) {
        await cubit.adjustHijri(1);
      }
      expect(hijri.adjustmentDays, 2);
      expect(cubit.state.hijriAdjustmentDays, 2);
      expect(cubit.state.hijriToday.day, 6);

      await cubit.adjustHijri(-1);
      expect(cubit.state.hijriToday.day, 5);
    });

    test('taps made while a save runs are not lost', () async {
      final cubit = make();
      await Future.wait([cubit.adjustHijri(1), cubit.adjustHijri(1)]);
      expect(hijri.adjustmentDays, 2);
    });

    test('suggests the method for the location\'s country', () async {
      expect(make().state.suggestedMethod, isNull); // Cairo has no code.

      location.lastKnown = alexandria;
      expect(make().state.suggestedMethod, CalculationMethod.egyptian);
    });

    test('the high-latitude rule shows only far from the equator', () async {
      expect(make().state.showsHighLatitudeRule, isFalse);

      final cubit = make();
      await location.useManualLocation(oslo);
      await pumpEventQueue();
      expect(cubit.state.showsHighLatitudeRule, isTrue);
    });

    test('a changed rule stays visible to change it back', () async {
      await settings.save(
        const PrayerCalculationSettings(
          highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
        ),
      );
      expect(make().state.showsHighLatitudeRule, isTrue);
    });
  });

  group('LocationSettingsCubit', () {
    late FakeLocationService location;

    LocationSettingsCubit make() {
      final cubit = LocationSettingsCubit(location);
      addTearDown(cubit.close);
      return cubit;
    }

    setUp(() {
      location = FakeLocationService(lastKnown: cairo, places: [alexandria]);
    });

    test('starts on the source in use', () {
      expect(make().state.source, LocationSource.automatic);
      location = FakeLocationService(lastKnown: cairo, manual: alexandria);
      final manual = make().state;
      expect(manual.source, LocationSource.manual);
      expect(manual.usingManual, isTrue);
      expect(manual.location, alexandria);
    });

    test('search waits for typing to pause, then lists matches', () async {
      const pause = Duration(milliseconds: 40);
      final cubit = LocationSettingsCubit(location, debounce: pause);
      addTearDown(cubit.close);

      cubit.search('A');
      expect(cubit.state.searchStatus, PlaceSearchStatus.idle);
      cubit
        ..search('Al')
        ..search('Alex');
      expect(cubit.state.searchStatus, PlaceSearchStatus.searching);
      await Future<void>.delayed(pause ~/ 2);
      expect(location.searches, isEmpty);

      await Future<void>.delayed(pause * 2);
      expect(location.searches, ['Alex']);
      expect(cubit.state.searchStatus, PlaceSearchStatus.done);
      expect(cubit.state.results, [alexandria]);
    });

    test('a failed search says so', () async {
      location.searchError = const PlaceSearchException('offline');
      final cubit = LocationSettingsCubit(location, debounce: Duration.zero);
      addTearDown(cubit.close);
      cubit.search('Alex');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.searchStatus, PlaceSearchStatus.failed);
      expect(cubit.state.results, isEmpty);
    });

    test('choosing a city uses it instead of the device', () async {
      final cubit = make()..showManual();
      await cubit.choose(alexandria);

      expect(location.isManual, isTrue);
      expect(location.lastKnown, alexandria);
      expect(cubit.state.usingManual, isTrue);
      expect(cubit.state.query, isEmpty);
    });

    test('Automatic switches back once the device finds a fix', () async {
      location = FakeLocationService(
        lastKnown: cairo,
        manual: alexandria,
        results: [LocationFound(cairo)],
      );
      final cubit = make();
      await cubit.showAutomatic();

      expect(location.isManual, isFalse);
      expect(cubit.state.source, LocationSource.automatic);
      expect(cubit.state.usingManual, isFalse);
      expect(cubit.state.location, cairo);
    });

    test('Automatic without a fix keeps the chosen city', () async {
      location = FakeLocationService(
        lastKnown: cairo,
        manual: alexandria,
        results: [const LocationFailed(LocationFailure.serviceDisabled)],
      );
      final cubit = make();
      await cubit.showAutomatic();

      expect(location.isManual, isTrue);
      expect(cubit.state.source, LocationSource.manual);
      expect(cubit.state.failure, LocationFailure.serviceDisabled);
      expect(cubit.state.location, alexandria);

      await cubit.openSettingsFor(LocationFailure.serviceDisabled);
      expect(location.locationSettingsOpened, 1);
    });

    test('Update location refreshes the device fix', () async {
      final cubit = make();
      await cubit.refresh();
      expect(location.permissionRequests, [true]);
      expect(cubit.state.locating, isFalse);
      expect(cubit.state.failure, isNull);
    });
  });
}
