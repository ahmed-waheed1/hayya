import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl_standalone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/data/adhan_preferences_repository_impl.dart';
import '../../features/notifications/domain/adhan_scheduler.dart';
import '../../features/notifications/domain/usecases/plan_adhan_notifications.dart';
import '../../features/notifications/presentation/localized_notification_texts.dart';
import '../../features/prayer_times/data/adhan_prayer_times_repository.dart';
import '../../features/prayer_times/data/prayer_settings_repository_impl.dart';
import '../preferences/app_preferences.dart';
import '../services/device_location_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../utils/app_locales.dart';
import '../utils/localized_format.dart';

/// Recalculates the prayer times and reschedules the adhan notifications
/// from what is saved on disk, while the app is closed. Run by the system
/// through `WorkmanagerBackgroundTasks`; see docs/background-reschedule.md.
///
/// It reuses the app's [AdhanScheduler], fed with a minimal set of
/// dependencies (not `configureDependencies`, which also opens the
/// tracker's Hive box, possibly while the app holds it). It never asks
/// for anything: the location is the cached fix or the chosen city, never
/// GPS or the network, and nothing shows a prompt or any UI.
///
/// Returns whether it ran; false only if something failed before the
/// scheduler took over (which logs its own failures).
///
/// Tests pass [notifications], [clock] and [assetLoader], and the device's
/// [deviceLocale] and [deviceUses24Hour], which are read from the platform
/// otherwise.
Future<bool> rescheduleAdhanInBackground({
  NotificationService? notifications,
  DateTime Function() clock = DateTime.now,
  AssetLoader assetLoader = const RootBundleAssetLoader(),
  Locale? deviceLocale,
  bool? deviceUses24Hour,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // The app may have changed them since this isolate's copy was read.
    await prefs.reload();
    final app = AppPreferences(prefs);

    // The language and digits the app itself would use (see app.dart).
    final locale = resolveAppLocale(
      app.languageCode,
      deviceLocale ?? _parseLocale(await findSystemLocale()),
    );
    await loadTranslationsWithoutContext(locale, assetLoader: assetLoader);
    final display = app.displayPreferences;
    final texts = LocalizedNotificationTexts(
      LocalizedFormat(
        locale,
        numerals: display.numerals,
        use24Hour: display.use24Hour(
          deviceUses24Hour:
              deviceUses24Hour ??
              app.deviceUses24Hour ??
              PlatformDispatcher.instance.alwaysUse24HourFormat,
        ),
      ),
    );

    final scheduler = AdhanScheduler(
      // Only its cached fix or chosen city is read; nothing here locates.
      locationService: DeviceLocationService(prefs),
      settingsRepository: PrayerSettingsRepositoryImpl(prefs),
      preferencesRepository: AdhanPreferencesRepositoryImpl(prefs),
      notifications: notifications ?? LocalNotificationService(),
      plan: const PlanAdhanNotifications(AdhanPrayerTimesRepository()),
      clock: clock,
    );
    await scheduler.useTexts(texts);
    await scheduler.dispose();
    debugPrint('Background adhan reschedule ran (${locale.languageCode}).');
    return true;
  } on Object catch (e, stack) {
    debugPrint('Background adhan reschedule failed: $e\n$stack');
    return false;
  }
}

/// "ar_EG" or "en-US" (as `findSystemLocale` reports it) as a [Locale].
Locale _parseLocale(String name) {
  final parts = name.split(RegExp('[_-]'));
  return Locale(parts.first, parts.length > 1 ? parts[1] : null);
}
