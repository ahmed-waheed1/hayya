import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/notification_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/notifications/data/adhan_preferences_repository_impl.dart';
import 'package:hayya/features/notifications/domain/adhan_scheduler.dart';
import 'package:hayya/features/notifications/domain/entities/adhan_preferences.dart';
import 'package:hayya/features/notifications/domain/entities/planned_notification.dart';
import 'package:hayya/features/notifications/domain/usecases/plan_adhan_notifications.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_location_service.dart';
import '../../../helpers/fake_notification_service.dart';

/// Texts in a made-up language, so tests can tell languages apart.
class _Texts implements NotificationTexts {
  const _Texts(this.tag);

  final String tag;

  @override
  ({String title, String body}) forNotification(PlannedNotification n) =>
      (title: '$tag ${n.kind.name} ${n.prayer.name}', body: tag);

  @override
  ChannelLabel channel(NotificationSound sound) =>
      (name: '$tag ${sound.name}', description: tag);
}

void main() {
  final makkah = UserLocation(
    coordinates: const GeoCoordinates(21.4225, 39.8262),
    updatedAt: DateTime(2026, 10, 15, 12),
  );

  late DateTime now;

  late FakeLocationService location;
  late PrayerSettingsRepositoryImpl settings;
  late AdhanPreferencesRepositoryImpl preferences;
  late FakeNotificationService notifications;
  late AdhanScheduler scheduler;

  setUp(() async {
    now = DateTime(2026, 10, 15, 13);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    location = FakeLocationService(
      lastKnown: cairo,
      results: [LocationFound(makkah)],
    );
    settings = PrayerSettingsRepositoryImpl(prefs);
    preferences = AdhanPreferencesRepositoryImpl(prefs);
    notifications = FakeNotificationService();
    scheduler = AdhanScheduler(
      locationService: location,
      settingsRepository: settings,
      preferencesRepository: preferences,
      notifications: notifications,
      plan: const PlanAdhanNotifications(AdhanPrayerTimesRepository()),
      clock: () => now,
    )..start();
    addTearDown(scheduler.dispose);
  });

  /// Lets stream listeners and the reschedule they start finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  DateTime firstAdhan(Prayer prayer) => notifications.pending
      .firstWhere((n) => n.title == 'en adhan ${prayer.name}')
      .at;

  group('applying the plan', () {
    test('nothing is scheduled before the texts are known', () async {
      await scheduler.reschedule();
      expect(notifications.replaceCalls, 0);
    });

    test('schedules the plan with its texts, sounds and channels', () async {
      await scheduler.useTexts(const _Texts('en'));

      expect(notifications.pending, hasLength(3 + 6 * 5));
      final first = notifications.pending.first;
      expect(first.title, 'en adhan asr');
      expect(first.sound, NotificationSound.adhan);
      expect(first.at.isAfter(now), isTrue);
      expect(notifications.channels.keys, NotificationSound.values);
      expect(notifications.channels[NotificationSound.adhan]!.name, 'en adhan');
    });

    test('reminders use the reminder sound', () async {
      await preferences.save(const AdhanPreferences(reminderOn: true));
      await scheduler.useTexts(const _Texts('en'));

      final reminder = notifications.pending.first;
      expect(reminder.title, 'en reminder asr');
      expect(reminder.sound, NotificationSound.reminder);
    });

    test('respects the service\'s pending cap', () async {
      notifications = FakeNotificationService(maxPending: 10);
      scheduler = AdhanScheduler(
        locationService: location,
        settingsRepository: settings,
        preferencesRepository: preferences,
        notifications: notifications,
        plan: const PlanAdhanNotifications(AdhanPrayerTimesRepository()),
        clock: () => now,
      );
      await scheduler.useTexts(const _Texts('en'));
      expect(notifications.pending, hasLength(10));
    });

    test('without a location, clears everything pending', () async {
      location.lastKnown = null;
      notifications.pending = [
        ScheduledNotification(
          id: 1,
          at: now,
          title: 'old',
          body: 'old',
          sound: NotificationSound.adhan,
        ),
      ];
      await scheduler.useTexts(const _Texts('en'));
      expect(notifications.replaceCalls, 1);
      expect(notifications.pending, isEmpty);
    });

    test('with nothing to schedule, a language change still renames the '
        'channels', () async {
      location.lastKnown = null;
      await scheduler.useTexts(const _Texts('en'));
      await scheduler.useTexts(const _Texts('ar'));

      expect(notifications.replaceCalls, 2);
      expect(notifications.pending, isEmpty);
      expect(notifications.channels[NotificationSound.adhan]!.name, 'ar adhan');
    });

    test('an unchanged plan isn\'t sent again', () async {
      await scheduler.useTexts(const _Texts('en'));
      await scheduler.reschedule();
      await scheduler.reschedule();
      expect(notifications.replaceCalls, 1);
    });

    test('force sends an unchanged plan again', () async {
      await scheduler.useTexts(const _Texts('en'));
      await scheduler.reschedule(force: true);
      expect(notifications.replaceCalls, 2);
    });

    test('calls during a run fold into one more run', () async {
      await scheduler.useTexts(const _Texts('en'));
      final runs = [
        scheduler.useTexts(const _Texts('ar')),
        scheduler.reschedule(),
        scheduler.reschedule(),
      ];
      await Future.wait(runs);
      expect(notifications.replaceCalls, 2);
      expect(notifications.pending.first.title, 'ar adhan asr');
    });

    test('a platform failure is caught, and the next run retries', () async {
      notifications.failNext = StateError('plugin');
      await scheduler.useTexts(const _Texts('en'));
      expect(notifications.pending, isEmpty);

      await scheduler.reschedule();
      expect(notifications.pending, isNotEmpty);
    });
  });

  group('test adhan', () {
    setUp(() => scheduler.useTexts(const _Texts('en')));

    ScheduledNotification? testAdhan() => notifications.pending
        .where((n) => n.id == AdhanScheduler.testId)
        .firstOrNull;

    test('adds an adhan one minute out, on the adhan sound', () async {
      final planned = notifications.pending.length;
      await scheduler.scheduleTest();

      expect(testAdhan()!.at, now.add(const Duration(minutes: 1)));
      expect(testAdhan()!.sound, NotificationSound.adhan);
      expect(testAdhan()!.title, startsWith('en adhan'));
      expect(notifications.pending, hasLength(planned + 1));
    });

    test('survives later reschedules until it fires', () async {
      await scheduler.scheduleTest();
      await preferences.save(const AdhanPreferences(reminderOn: true));
      await Future<void>.delayed(Duration.zero);
      expect(testAdhan(), isNotNull);

      now = now.add(const Duration(minutes: 2));
      await scheduler.reschedule();
      expect(testAdhan(), isNull);
    });

    test('takes a slot from the plan under the cap', () async {
      notifications = FakeNotificationService(maxPending: 10);
      scheduler = AdhanScheduler(
        locationService: location,
        settingsRepository: settings,
        preferencesRepository: preferences,
        notifications: notifications,
        plan: const PlanAdhanNotifications(AdhanPrayerTimesRepository()),
        clock: () => now,
      );
      await scheduler.useTexts(const _Texts('en'));
      await scheduler.scheduleTest();
      expect(notifications.pending, hasLength(10));
      expect(testAdhan(), isNotNull);
    });
  });

  group('reschedule triggers', () {
    setUp(() => scheduler.useTexts(const _Texts('en')));

    test('a language change rewrites the pending texts', () async {
      await scheduler.useTexts(const _Texts('ar'));
      expect(notifications.replaceCalls, 2);
      expect(notifications.pending.first.title, 'ar adhan asr');
      expect(notifications.channels[NotificationSound.adhan]!.name, 'ar adhan');
    });

    test('a new location moves the times', () async {
      final cairoMaghrib = firstAdhan(Prayer.maghrib);
      await location.locate();
      await settle();

      expect(notifications.replaceCalls, 2);
      expect(firstAdhan(Prayer.maghrib), isNot(cairoMaghrib));
    });

    test('new calculation settings move the times', () async {
      final shafiAsr = firstAdhan(Prayer.asr);
      await settings.save(
        const PrayerCalculationSettings(madhab: AsrMadhab.hanafi),
      );
      await settle();

      expect(notifications.replaceCalls, 2);
      expect(firstAdhan(Prayer.asr).isAfter(shafiAsr), isTrue);
    });

    test('a minute adjustment moves that adhan by exactly that much', () async {
      final fajr = firstAdhan(Prayer.fajr);
      final isha = firstAdhan(Prayer.isha);
      await settings.save(
        const PrayerCalculationSettings().withAdjustment(Prayer.fajr, 7),
      );
      await settle();

      expect(notifications.replaceCalls, 2);
      expect(firstAdhan(Prayer.fajr), fajr.add(const Duration(minutes: 7)));
      expect(firstAdhan(Prayer.isha), isha);
    });

    test('a manually chosen city moves the times', () async {
      final cairoMaghrib = firstAdhan(Prayer.maghrib);
      await location.useManualLocation(
        UserLocation(
          coordinates: const GeoCoordinates(21.4225, 39.8262),
          updatedAt: now,
        ),
      );
      await settle();

      expect(notifications.replaceCalls, 2);
      expect(firstAdhan(Prayer.maghrib), isNot(cairoMaghrib));
    });

    test('the adhan plays on the alarm channel by default', () async {
      final adhans = notifications.pending.where(
        (n) => n.title.startsWith('en adhan'),
      );
      expect(adhans, isNotEmpty);
      expect(adhans.map((n) => n.sound).toSet(), {NotificationSound.adhan});
    });

    test('notification volume moves every adhan to its own channel, and '
        'back', () async {
      await preferences.save(
        const AdhanPreferences(
          reminderOn: true,
          volume: AdhanVolume.notification,
        ),
      );
      await settle();

      expect(notifications.replaceCalls, 2);
      final adhans = notifications.pending.where(
        (n) => n.title.startsWith('en adhan'),
      );
      expect(adhans.map((n) => n.sound).toSet(), {
        NotificationSound.adhanNotificationVolume,
      });
      // Reminders keep their own channel.
      final reminders = notifications.pending.where(
        (n) => n.title.startsWith('en reminder'),
      );
      expect(reminders.map((n) => n.sound).toSet(), {
        NotificationSound.reminder,
      });
      // Every channel exists, so switching never waits on one.
      expect(
        notifications.channels.keys.toSet(),
        NotificationSound.values.toSet(),
      );

      await preferences.save(const AdhanPreferences(reminderOn: true));
      await settle();
      expect(notifications.replaceCalls, 3);
      expect(
        notifications.pending
            .where((n) => n.title.startsWith('en adhan'))
            .map((n) => n.sound)
            .toSet(),
        {NotificationSound.adhan},
      );
    });

    test('the test adhan follows the volume choice', () async {
      await preferences.save(
        const AdhanPreferences(volume: AdhanVolume.notification),
      );
      await scheduler.scheduleTest();
      final test = notifications.pending.singleWhere(
        (n) => n.id == AdhanScheduler.testId,
      );
      expect(test.sound, NotificationSound.adhanNotificationVolume);
    });

    test('switching a prayer off removes its adhan', () async {
      await preferences.save(
        const AdhanPreferences().withPrayer(Prayer.maghrib, on: false),
      );
      await settle();

      expect(notifications.replaceCalls, 2);
      expect(
        notifications.pending.any((n) => n.title.endsWith('maghrib')),
        isFalse,
      );
    });

    test('turning the reminder on adds reminders', () async {
      await preferences.save(const AdhanPreferences(reminderOn: true));
      await settle();

      expect(
        notifications.pending.where(
          (n) => n.sound == NotificationSound.reminder,
        ),
        isNotEmpty,
      );
    });

    test(
      'time passing (app reopened later) drops what already fired',
      () async {
        final scheduled = notifications.pending.length;
        now = now.add(const Duration(hours: 3));
        await scheduler.reschedule();

        expect(notifications.replaceCalls, 2);
        expect(notifications.pending.first.title, 'en adhan maghrib');
        expect(notifications.pending, hasLength(scheduled - 1));
      },
    );

    test('after dispose, changes no longer reschedule', () async {
      await scheduler.dispose();
      await settings.save(
        const PrayerCalculationSettings(madhab: AsrMadhab.hanafi),
      );
      await settle();
      expect(notifications.replaceCalls, 1);
    });
  });
}
