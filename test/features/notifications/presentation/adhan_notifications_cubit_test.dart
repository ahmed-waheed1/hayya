import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/notifications/data/adhan_preferences_repository_impl.dart';
import 'package:hayya/core/services/notification_service.dart';
import 'package:hayya/features/notifications/domain/adhan_scheduler.dart';
import 'package:hayya/features/notifications/domain/entities/planned_notification.dart';
import 'package:hayya/features/notifications/domain/entities/adhan_preferences.dart';
import 'package:hayya/features/notifications/domain/usecases/plan_adhan_notifications.dart';
import 'package:hayya/features/notifications/presentation/cubit/adhan_notifications_cubit.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_location_service.dart';
import '../../../helpers/fake_notification_service.dart';

void main() {
  late SharedPreferences prefs;
  late AdhanPreferencesRepositoryImpl repository;
  late FakeNotificationService notifications;
  late FakeLocationService location;
  late AdhanScheduler scheduler;

  Future<void> setUpWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    repository = AdhanPreferencesRepositoryImpl(prefs);
    notifications = FakeNotificationService(allowed: false);
    location = FakeLocationService(lastKnown: cairo);
  }

  setUp(() => setUpWith({}));

  AdhanNotificationsCubit makeCubit() {
    scheduler = AdhanScheduler(
      locationService: location,
      settingsRepository: PrayerSettingsRepositoryImpl(prefs),
      preferencesRepository: repository,
      notifications: notifications,
      plan: const PlanAdhanNotifications(AdhanPrayerTimesRepository()),
    );
    final cubit = AdhanNotificationsCubit(
      repository: repository,
      notifications: notifications,
      locationService: location,
      scheduler: scheduler,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('preferences', () {
    test('default: every adhan on, reminder off at 10 minutes', () {
      expect(repository.preferences, const AdhanPreferences());
      expect(repository.preferences.enabled, {
        Prayer.fajr,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      });
      expect(repository.preferences.reminderOn, isFalse);
      expect(repository.preferences.reminderMinutes, 10);
    });

    test('survive a reload', () async {
      await repository.save(
        const AdhanPreferences(
          enabled: {Prayer.fajr, Prayer.isha},
          reminderOn: true,
          reminderMinutes: 30,
        ),
      );
      final reloaded = AdhanPreferencesRepositoryImpl(prefs);
      expect(reloaded.preferences.enabled, {Prayer.fajr, Prayer.isha});
      expect(reloaded.preferences.reminderOn, isTrue);
      expect(reloaded.preferences.reminderMinutes, 30);
    });

    test('unknown stored values fall back safely', () async {
      await setUpWith({
        'adhan_prayers': ['fajr', 'sunrise', 'tahajjud'],
        'adhan_reminder_minutes': 7,
      });
      expect(repository.preferences.enabled, {Prayer.fajr});
      expect(repository.preferences.reminderMinutes, 10);
    });

    test('every prayer off is kept as off', () async {
      await repository.save(const AdhanPreferences(enabled: {}));
      expect(
        AdhanPreferencesRepositoryImpl(prefs).preferences.enabled,
        isEmpty,
      );
    });
  });

  group('cubit', () {
    test('the bell saves the prayer\'s adhan', () async {
      notifications.allowed = true;
      final cubit = makeCubit();
      await cubit.setAdhan(Prayer.asr, on: false);

      expect(cubit.state.preferences.isEnabled(Prayer.asr), isFalse);
      expect(repository.preferences.isEnabled(Prayer.asr), isFalse);
    });

    test('turning something on asks for permission when blocked', () async {
      final cubit = makeCubit();
      await cubit.setAdhan(Prayer.asr, on: false);
      expect(notifications.permissionRequests, 0);

      await cubit.setReminderOn(true);
      expect(notifications.permissionRequests, 1);
      expect(cubit.state.notificationsAllowed, isTrue);
      expect(repository.preferences.reminderOn, isTrue);
    });

    test('the lead time is kept while the reminder is off', () async {
      final cubit = makeCubit();
      await cubit.setReminderMinutes(15);
      await cubit.setReminderOn(true);
      await cubit.setReminderOn(false);
      expect(repository.preferences.reminderMinutes, 15);
      expect(repository.preferences.reminder, isNull);
    });

    test('first run asks once, straight away with a known location', () async {
      await makeCubit().start();
      expect(notifications.permissionRequests, 1);
      expect(repository.permissionPrompted, isTrue);

      await makeCubit().start();
      expect(notifications.permissionRequests, 1);
    });

    test('first run without a location waits for one before asking', () async {
      location = FakeLocationService();
      await makeCubit().start();
      expect(notifications.permissionRequests, 0);

      await location.locate();
      await Future<void>.delayed(Duration.zero);
      expect(notifications.permissionRequests, 1);
    });

    test('"Turn on" opens the settings once the prompt was used', () async {
      final cubit = makeCubit();
      await cubit.start();
      notifications.allowed = false;
      await cubit.refreshPermissions();

      await cubit.allowNotifications();
      expect(notifications.settingsOpened, 1);
      expect(notifications.permissionRequests, 1);
    });

    test(
      'exact alarms: reported, requested, and rescheduled once granted',
      () async {
        notifications
          ..allowed = true
          ..exact = false;
        final cubit = makeCubit();
        await cubit.start();
        await scheduler.useTexts(const _Texts());
        expect(cubit.state.exactAlarmsAllowed, isFalse);

        await cubit.allowExactAlarms();
        expect(notifications.exactRequests, 1);

        // The user allowed it in the system settings, then came back.
        notifications.exact = true;
        await cubit.refreshPermissions();
        expect(cubit.state.exactAlarmsAllowed, isTrue);
        // The same plan again, now as exact alarms.
        expect(notifications.replaceCalls, 2);

        await cubit.refreshPermissions();
        expect(notifications.replaceCalls, 2);
      },
    );
  });
}

class _Texts implements NotificationTexts {
  const _Texts();

  @override
  ({String title, String body}) forNotification(PlannedNotification n) =>
      (title: n.prayer.name, body: '');

  @override
  ChannelLabel channel(NotificationSound sound) =>
      (name: sound.name, description: '');
}
