import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/data/adhan_preferences_repository_impl.dart';
import '../../features/notifications/domain/adhan_scheduler.dart';
import '../../features/notifications/domain/repositories/adhan_preferences_repository.dart';
import '../../features/notifications/domain/usecases/plan_adhan_notifications.dart';
import '../../features/notifications/presentation/cubit/adhan_notifications_cubit.dart';
import '../../features/prayer_times/data/adhan_prayer_times_repository.dart';
import '../../features/prayer_times/data/hijri_calendar_repository_impl.dart';
import '../../features/prayer_times/data/prayer_settings_repository_impl.dart';
import '../../features/prayer_times/domain/repositories/hijri_calendar_repository.dart';
import '../../features/prayer_times/domain/repositories/prayer_settings_repository.dart';
import '../../features/prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../features/prayer_times/domain/usecases/get_hijri_date.dart';
import '../../features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import '../../features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import '../preferences/app_preferences.dart';
import '../services/device_location_service.dart';
import '../services/local_notification_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../theme/theme_mode_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<AppPreferences>(AppPreferences(prefs))
    ..registerLazySingleton<ThemeModeCubit>(
      () => ThemeModeCubit(getIt<AppPreferences>()),
    )
    ..registerLazySingleton<LocationService>(() => DeviceLocationService(prefs))
    // Prayer times
    ..registerLazySingleton<PrayerTimesRepository>(
      () => const AdhanPrayerTimesRepository(),
    )
    ..registerLazySingleton<PrayerSettingsRepository>(
      () => PrayerSettingsRepositoryImpl(prefs),
    )
    ..registerLazySingleton<HijriCalendarRepository>(
      () => const HijriCalendarRepositoryImpl(),
    )
    ..registerFactory<GetPrayerSchedule>(
      () => GetPrayerSchedule(getIt<PrayerTimesRepository>()),
    )
    ..registerFactory<GetHijriDate>(
      () => GetHijriDate(getIt<HijriCalendarRepository>()),
    )
    ..registerFactory<PrayerTimesCubit>(
      () => PrayerTimesCubit(
        locationService: getIt<LocationService>(),
        settingsRepository: getIt<PrayerSettingsRepository>(),
        getSchedule: getIt<GetPrayerSchedule>(),
        getHijriDate: getIt<GetHijriDate>(),
      ),
    )
    // Adhan notifications
    ..registerLazySingleton<NotificationService>(LocalNotificationService.new)
    ..registerLazySingleton<AdhanPreferencesRepository>(
      () => AdhanPreferencesRepositoryImpl(prefs),
    )
    ..registerFactory<PlanAdhanNotifications>(
      () => PlanAdhanNotifications(getIt<PrayerTimesRepository>()),
    )
    ..registerLazySingleton<AdhanScheduler>(
      () => AdhanScheduler(
        locationService: getIt<LocationService>(),
        settingsRepository: getIt<PrayerSettingsRepository>(),
        preferencesRepository: getIt<AdhanPreferencesRepository>(),
        notifications: getIt<NotificationService>(),
        plan: getIt<PlanAdhanNotifications>(),
      ),
    )
    ..registerLazySingleton<AdhanNotificationsCubit>(
      () => AdhanNotificationsCubit(
        repository: getIt<AdhanPreferencesRepository>(),
        notifications: getIt<NotificationService>(),
        locationService: getIt<LocationService>(),
        scheduler: getIt<AdhanScheduler>(),
      ),
    );
}
