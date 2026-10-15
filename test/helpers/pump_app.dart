import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hayya/app.dart';
import 'package:hayya/core/di/injection.dart';
import 'package:hayya/core/preferences/app_preferences.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/notification_service.dart';
import 'package:hayya/features/notifications/domain/adhan_scheduler.dart';
import 'package:hayya/features/notifications/domain/repositories/adhan_preferences_repository.dart';
import 'package:hayya/features/notifications/domain/usecases/plan_adhan_notifications.dart';
import 'package:hayya/features/prayer_times/domain/repositories/hijri_calendar_repository.dart';
import 'package:hayya/features/prayer_times/domain/repositories/prayer_settings_repository.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_hijri_date.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:hayya/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_location_service.dart';
import 'fake_notification_service.dart';

const phoneSize = Size(390, 844);
const tabletSize = Size(1194, 834);

/// Lets real async work (asset loading, fonts, translations) finish.
/// `GoogleFonts.pendingFonts()` hangs inside the fake-async zone.
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Scrolls [finder] into view within its own scrollable, then taps it.
/// Settings is longer than a phone screen.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

/// Renders every bundled family and weight once so later layouts measure
/// with the real fonts, not the 1-em placeholder.
Future<void> loadFonts(WidgetTester tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  const weights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ];
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          for (final family in ['Manrope', 'Cairo'])
            for (final w in weights)
              Text('Aa حيّ', style: GoogleFonts.getFont(family, fontWeight: w)),
        ],
      ),
    ),
  );
  await settle(tester);
}

/// Boots the full app (DI, preferences, translations, router) at [size].
///
/// Location comes from [location] (by default Cairo, cached and found).
/// [now] fixes the clock Home and the adhan schedule use. Notifications go to
/// [notifications] (by default a fresh fake), never the plugin.
Future<void> pumpHayyaApp(
  WidgetTester tester, {
  Size size = phoneSize,
  Map<String, Object> prefs = const {},
  LocationService? location,
  DateTime Function()? now,
  NotificationService? notifications,
  AssetLoader? assetLoader,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // A cached asset future from an earlier test never completes in this
  // test's zone, so translations would hang on the second boot.
  rootBundle.clear();
  SharedPreferences.setMockInitialValues(prefs);
  await getIt.reset();
  await configureDependencies();
  getIt
    ..unregister<LocationService>()
    ..registerSingleton<LocationService>(
      location ?? FakeLocationService(lastKnown: cairo),
    )
    ..unregister<NotificationService>()
    ..registerSingleton<NotificationService>(
      notifications ?? FakeNotificationService(),
    )
    ..unregister<AdhanScheduler>()
    ..registerLazySingleton<AdhanScheduler>(
      () => AdhanScheduler(
        locationService: getIt<LocationService>(),
        settingsRepository: getIt<PrayerSettingsRepository>(),
        preferencesRepository: getIt<AdhanPreferencesRepository>(),
        notifications: getIt<NotificationService>(),
        plan: getIt<PlanAdhanNotifications>(),
        clock: now ?? DateTime.now,
      ),
    )
    ..unregister<PrayerTimesCubit>()
    ..registerFactory<PrayerTimesCubit>(
      () => PrayerTimesCubit(
        locationService: getIt<LocationService>(),
        settingsRepository: getIt<PrayerSettingsRepository>(),
        getSchedule: getIt<GetPrayerSchedule>(),
        getHijriDate: getIt<GetHijriDate>(),
        hijriCalendar: getIt<HijriCalendarRepository>(),
        clock: now ?? DateTime.now,
      ),
    );
  await EasyLocalization.ensureInitialized();

  await loadFonts(tester);
  await tester.pumpWidget(
    localizedApp(
      getIt<AppPreferences>().languageCode,
      assetLoader: assetLoader ?? const RootBundleAssetLoader(),
    ),
  );
  await settle(tester);
}
