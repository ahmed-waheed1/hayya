import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/preferences/app_preferences.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/features/notifications/data/adhan_preferences_repository_impl.dart';
import 'package:hayya/features/onboarding/domain/onboarding_status.dart';
import 'package:hayya/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:hayya/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_location_service.dart';

void main() {
  late SharedPreferences prefs;
  late AppPreferences appPreferences;
  late AdhanPreferencesRepositoryImpl adhanPreferences;

  Future<void> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    appPreferences = AppPreferences(prefs);
    adhanPreferences = AdhanPreferencesRepositoryImpl(prefs);
  }

  setUp(() => prefsWith({}));

  OnboardingStatus statusWith(FakeLocationService location) => OnboardingStatus(
    preferences: appPreferences,
    locationService: location,
    adhanPreferences: adhanPreferences,
  );

  /// [notificationsAllowed] is what the permission prompt answers.
  ({OnboardingCubit cubit, List<int> notificationAsks}) cubitWith(
    FakeLocationService location, {
    bool notificationsAllowed = true,
  }) {
    final asks = <int>[];
    final cubit = OnboardingCubit(
      status: statusWith(location),
      locationService: location,
      settingsRepository: PrayerSettingsRepositoryImpl(prefs),
      getSchedule: GetPrayerSchedule(const AdhanPrayerTimesRepository()),
      requestNotifications: () async {
        asks.add(1);
        return notificationsAllowed;
      },
      clock: () => DateTime(2026, 10, 15, 13),
    );
    addTearDown(cubit.close);
    return (cubit: cubit, notificationAsks: asks);
  }

  group('shown only on first launch', () {
    test('a fresh install shows it', () {
      expect(statusWith(FakeLocationService()).shouldShow, isTrue);
    });

    test('finished or skipped, it never shows again', () async {
      final status = statusWith(FakeLocationService());
      await status.complete();
      expect(status.shouldShow, isFalse);
      expect(prefs.getBool('onboarding_done'), isTrue);
    });

    test(
      'someone who used the app before onboarding existed skips it',
      () async {
        expect(
          statusWith(FakeLocationService(lastKnown: cairo)).shouldShow,
          isFalse,
        );

        await adhanPreferences.markPermissionPrompted();
        expect(statusWith(FakeLocationService()).shouldShow, isFalse);
      },
    );
  });

  test('pages forward and back', () {
    final (:cubit, notificationAsks: _) = cubitWith(FakeLocationService());
    expect(cubit.state.page, OnboardingPage.welcome);
    cubit.next();
    expect(cubit.state.page, OnboardingPage.location);
    cubit.next();
    expect(cubit.state.page, OnboardingPage.notifications);
    cubit.back();
    expect(cubit.state.page, OnboardingPage.location);
    cubit
      ..back()
      ..back();
    expect(cubit.state.page, OnboardingPage.welcome);
  });

  group('location', () {
    test('allowed: prompts once, then on to notifications', () async {
      final location = FakeLocationService();
      final (:cubit, notificationAsks: _) = cubitWith(location);
      cubit.next();
      await cubit.allowLocation();

      expect(location.permissionRequests, [true]);
      expect(cubit.state.location, cairo);
      expect(cubit.state.page, OnboardingPage.notifications);
      // The next prayer at 13:00 in Cairo, for the notification slide.
      expect(cubit.state.nextPrayer?.prayer, Prayer.asr);
    });

    test('denied: explains, and continuing is still possible', () async {
      final location = FakeLocationService(
        results: [const LocationFailed(LocationFailure.permissionDenied)],
      );
      final (:cubit, notificationAsks: _) = cubitWith(location);
      cubit.next();
      await cubit.allowLocation();

      expect(cubit.state.page, OnboardingPage.location);
      expect(cubit.state.locationFailure, LocationFailure.permissionDenied);
      expect(cubit.state.locating, isFalse);

      cubit.next();
      expect(cubit.state.page, OnboardingPage.notifications);
      expect(cubit.state.location, isNull);
    });

    test('a city chosen by hand moves on', () async {
      final location = FakeLocationService(
        results: [const LocationFailed(LocationFailure.permissionDenied)],
      );
      final (:cubit, notificationAsks: _) = cubitWith(location);
      cubit.next();
      await cubit.allowLocation();
      await location.useManualLocation(alexandria);

      expect(cubit.state.location, alexandria);
      expect(cubit.state.locationFailure, isNull);
      expect(cubit.state.page, OnboardingPage.notifications);
    });

    test(
      'back from the system settings, checks again without prompting',
      () async {
        final location = FakeLocationService(
          results: [
            const LocationFailed(LocationFailure.permissionDeniedForever),
            LocationFound(cairo),
          ],
        );
        final (:cubit, notificationAsks: _) = cubitWith(location);
        cubit.next();
        await cubit.allowLocation();
        await cubit.openSettingsFor(LocationFailure.permissionDeniedForever);
        expect(location.appSettingsOpened, 1);

        await cubit.recheckLocation();
        expect(location.permissionRequests, [true, false]);
        expect(cubit.state.page, OnboardingPage.notifications);
      },
    );

    test('rechecks only after a failure on the location slide', () async {
      final location = FakeLocationService();
      final (:cubit, notificationAsks: _) = cubitWith(location);
      await cubit.recheckLocation();
      cubit.next();
      await cubit.recheckLocation();
      expect(location.permissionRequests, isEmpty);
    });
  });

  group('notifications', () {
    test('allowed: finishes, saved', () async {
      final (:cubit, :notificationAsks) = cubitWith(FakeLocationService());
      cubit
        ..next()
        ..next();
      await cubit.allowNotifications();

      expect(notificationAsks, hasLength(1));
      expect(cubit.state.done, isTrue);
      expect(appPreferences.onboardingDone, isTrue);
    });

    test('refused: explains, then Continue finishes', () async {
      final (:cubit, :notificationAsks) = cubitWith(
        FakeLocationService(),
        notificationsAllowed: false,
      );
      cubit
        ..next()
        ..next();
      await cubit.allowNotifications();

      expect(cubit.state.notificationsDenied, isTrue);
      expect(cubit.state.done, isFalse);

      await cubit.finish();
      expect(cubit.state.done, isTrue);
      expect(appPreferences.onboardingDone, isTrue);
    });
  });

  test('skipping finishes at once, without any prompt', () async {
    final location = FakeLocationService();
    final (:cubit, :notificationAsks) = cubitWith(location);
    await cubit.finish();

    expect(cubit.state.done, isTrue);
    expect(appPreferences.onboardingDone, isTrue);
    expect(location.permissionRequests, isEmpty);
    expect(notificationAsks, isEmpty);
  });
}
