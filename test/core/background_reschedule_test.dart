import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/di/background_reschedule.dart';
import 'package:hayya/core/services/notification_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/notifications/data/adhan_preferences_repository_impl.dart';
import 'package:hayya/features/notifications/domain/entities/planned_notification.dart';
import 'package:hayya/features/notifications/domain/usecases/plan_adhan_notifications.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_location_service.dart';
import '../helpers/fake_notification_service.dart';

/// The location plugins' channels. The background run must never use them:
/// no GPS, no geocoding, no permission prompt.
const _locationChannels = [
  'flutter.baseflow.com/permissions/methods',
  'flutter.baseflow.com/geolocator',
  'flutter.baseflow.com/geolocator_android',
  'flutter.baseflow.com/geocoding',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 15, 13);
  late FakeNotificationService notifications;
  late List<MethodCall> locationCalls;

  setUp(() {
    rootBundle.clear();
    notifications = FakeNotificationService();
    locationCalls = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _locationChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        locationCalls.add(call);
        return null;
      });
    }
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _locationChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  });

  /// Saved state as the app leaves it: a cached fix (or [manual] city),
  /// plus [prefs].
  void saved({
    UserLocation? cached,
    UserLocation? manual,
    Map<String, Object> prefs = const {},
  }) => SharedPreferences.setMockInitialValues({
    'onboarding_done': true,
    if (cached != null) 'last_location': jsonEncode(cached.toJson()),
    if (manual != null) 'manual_location': jsonEncode(manual.toJson()),
    ...prefs,
  });

  Future<bool> run({
    Locale deviceLocale = const Locale('en', 'US'),
    bool deviceUses24Hour = false,
  }) => rescheduleAdhanInBackground(
    notifications: notifications,
    clock: () => now,
    deviceLocale: deviceLocale,
    deviceUses24Hour: deviceUses24Hour,
  );

  /// What the app's own planner wants for [location] with the saved
  /// settings.
  Future<List<PlannedNotification>> expectedFor(
    UserLocation location, {
    int limit = 64,
    int days = PlanAdhanNotifications.days,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return const PlanAdhanNotifications(AdhanPrayerTimesRepository())(
      now: now,
      coordinates: location.coordinates,
      settings: PrayerSettingsRepositoryImpl(prefs).settings,
      preferences: AdhanPreferencesRepositoryImpl(prefs).preferences,
      limit: limit,
      days: days,
    );
  }

  List<(int, DateTime)> idsAndTimes(Iterable<Object> items) => [
    for (final item in items)
      switch (item) {
        ScheduledNotification(:final id, :final at) => (id, at),
        PlannedNotification(:final id, :final at) => (id, at),
        _ => throw ArgumentError(item),
      },
  ];

  group('schedule', () {
    test('the same plan the app makes, from the cached fix', () async {
      saved(cached: cairo, prefs: {'adhan_reminder_on': true});

      expect(await run(), isTrue);

      expect(notifications.replaceCalls, 1);
      expect(
        idsAndTimes(notifications.pending),
        idsAndTimes(await expectedFor(cairo)),
      );
      expect(notifications.pending.map((n) => n.sound).toSet(), {
        NotificationSound.adhan,
        NotificationSound.reminder,
      });
    });

    test('a city chosen by hand wins over the cached fix', () async {
      saved(cached: cairo, manual: alexandria);

      await run();

      expect(
        idsAndTimes(notifications.pending),
        idsAndTimes(await expectedFor(alexandria)),
      );
    });

    test('only the prayers switched on', () async {
      saved(
        cached: cairo,
        prefs: {
          'adhan_prayers': <String>['fajr'],
        },
      );

      await run();

      final expected = await expectedFor(cairo);
      expect(expected, isNotEmpty);
      expect(idsAndTimes(notifications.pending), idsAndTimes(expected));
      // Today's Fajr is past; one a day for the six days after.
      expect(notifications.pending, hasLength(PlanAdhanNotifications.days - 1));
    });

    test('iOS: fills all 64 slots, further ahead than a week', () async {
      saved(cached: cairo);
      notifications = FakeNotificationService(maxPending: 64, planDays: 64);

      await run();

      expect(notifications.pending, hasLength(64));
      expect(
        idsAndTimes(notifications.pending),
        idsAndTimes(await expectedFor(cairo, days: 64)),
      );
      expect(
        notifications.pending.last.at.isAfter(now.add(const Duration(days: 7))),
        isTrue,
      );
    });
  });

  group('language', () {
    test('the chosen language and Arabic-Indic digits', () async {
      saved(
        cached: cairo,
        prefs: {
          'language_code': 'ar',
          'adhan_reminder_on': true,
          'adhan_reminder_minutes': 10,
        },
      );

      await run(deviceLocale: const Locale('en', 'US'));

      final adhan = notifications.pending.firstWhere(
        (n) => n.sound == NotificationSound.adhan,
      );
      expect(adhan.title, 'حان الآن موعد صلاة العصر');
      expect(adhan.body, 'حيّ على الصلاة');
      final reminder = notifications.pending.firstWhere(
        (n) => n.sound == NotificationSound.reminder,
      );
      expect(reminder.title, 'بقيت ١٠ دقائق على أذان العصر');
      expect(reminder.body, isNot(contains(RegExp('[0-9]'))));
      expect(reminder.body, contains(RegExp('[٠-٩]')));
      expect(notifications.channels[NotificationSound.adhan]?.name, 'الأذان');
    });

    test('Western digits when chosen', () async {
      saved(
        cached: cairo,
        prefs: {
          'language_code': 'ar',
          'numerals': 'western',
          'adhan_reminder_on': true,
          'adhan_reminder_minutes': 10,
        },
      );

      await run();

      final reminder = notifications.pending.firstWhere(
        (n) => n.sound == NotificationSound.reminder,
      );
      expect(reminder.title, 'بقيت 10 دقائق على أذان العصر');
      expect(reminder.body, isNot(contains(RegExp('[٠-٩]'))));
    });

    test('with no language chosen, the device\'s', () async {
      saved(cached: cairo);
      await run(deviceLocale: const Locale('ar', 'EG'));
      expect(notifications.pending.first.title, 'حان الآن موعد صلاة العصر');

      saved(cached: cairo);
      await run(deviceLocale: const Locale('fr', 'FR'));
      expect(notifications.pending.first.title, 'It’s time for Asr');
    });

    test('the chosen language wins over the device\'s', () async {
      saved(cached: cairo, prefs: {'language_code': 'en'});
      await run(deviceLocale: const Locale('ar', 'EG'));
      expect(notifications.pending.first.title, 'It’s time for Asr');
    });

    group('clock', () {
      /// The first reminder of the run: before Asr, in the afternoon.
      Future<String> reminderBody({
        Map<String, Object> prefs = const {},
        bool? deviceUses24Hour,
      }) async {
        saved(
          cached: cairo,
          prefs: {'language_code': 'en', 'adhan_reminder_on': true, ...prefs},
        );
        await rescheduleAdhanInBackground(
          notifications: notifications,
          clock: () => now,
          deviceLocale: const Locale('en'),
          deviceUses24Hour: deviceUses24Hour,
        );
        return notifications.pending
            .firstWhere((n) => n.sound == NotificationSound.reminder)
            .body;
      }

      test('the chosen 12/24-hour format', () async {
        expect(
          await reminderBody(prefs: {'time_format': 'twentyFourHour'}),
          contains(RegExp(r'\b1[5-9]:\d\d\b')),
        );
        expect(
          await reminderBody(
            prefs: {'time_format': 'twelveHour'},
            deviceUses24Hour: true,
          ),
          contains(RegExp(r'\b[3-7]:\d\d PM\b')),
        );
      });

      test('otherwise the device clock the app last saw', () async {
        expect(
          await reminderBody(prefs: {'device_uses_24_hour': true}),
          contains(RegExp(r'\b1[5-9]:\d\d\b')),
        );
        expect(
          await reminderBody(prefs: {'device_uses_24_hour': false}),
          contains(RegExp(r'\b[3-7]:\d\d PM\b')),
        );
      });
    });
  });

  group('never asks for anything', () {
    test('no GPS, geocoding or permission prompt', () async {
      saved(cached: cairo);
      await run();
      expect(notifications.pending, isNotEmpty);
      expect(locationCalls, isEmpty);
      expect(notifications.permissionRequests, 0);
      expect(notifications.exactRequests, 0);
    });

    test(
      'with no location yet, nothing is scheduled and nothing asked',
      () async {
        saved();
        expect(await run(), isTrue);
        expect(notifications.pending, isEmpty);
        expect(locationCalls, isEmpty);
        expect(notifications.permissionRequests, 0);
      },
    );
  });
}
