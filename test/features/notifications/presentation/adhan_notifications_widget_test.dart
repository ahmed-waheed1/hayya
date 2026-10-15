import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/di/injection.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/notification_service.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/notifications/domain/adhan_scheduler.dart';
import 'package:hayya/features/notifications/domain/repositories/adhan_preferences_repository.dart';
import 'package:hayya/features/notifications/presentation/widgets/notification_settings_group.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';

import '../../../helpers/fake_location_service.dart';
import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/pump_app.dart';

final midday = DateTime(2026, 10, 15, 13);

void main() {
  late FakeNotificationService notifications;

  Future<void> pump(
    WidgetTester tester, {
    String lang = 'en',
    Size size = phoneSize,
    FakeNotificationService? service,
  }) async {
    notifications = service ?? FakeNotificationService();
    final origin = tester.binding.clock.now();
    await pumpHayyaApp(
      tester,
      size: size,
      prefs: {'language_code': lang},
      notifications: notifications,
      now: () => midday.add(tester.binding.clock.now().difference(origin)),
    );
  }

  Future<void> openSettings(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(HayyaNavBar), matching: find.text(label)),
    );
    await settle(tester, rounds: 2);
  }

  Iterable<ScheduledNotification> adhansNamed(String title) =>
      notifications.pending.where((n) => n.title == title);

  testWidgets('opening the app schedules the adhan in English', (tester) async {
    await pump(tester);

    expect(notifications.pending, isNotEmpty);
    expect(adhansNamed('It’s time for Fajr'), hasLength(6));
    expect(
      notifications.pending.every((n) => n.sound == NotificationSound.adhan),
      isTrue,
    );
    expect(notifications.channels[NotificationSound.adhan]!.name, 'Adhan');
    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing is ever scheduled before translations load', (
    tester,
  ) async {
    // Translations arrive late, as on a cold start on a device.
    final loader = _GatedLoader();
    notifications = FakeNotificationService();
    await pumpHayyaApp(
      tester,
      prefs: {'language_code': 'en'},
      notifications: notifications,
      assetLoader: loader,
    );
    expect(notifications.calls, isEmpty);

    loader.gate.complete();
    await settle(tester);

    expect(notifications.calls, isNotEmpty);
    for (final (:notifications, :channels) in notifications.calls) {
      final texts = [
        for (final n in notifications) ...[n.title, n.body],
        for (final c in channels.values) ...[c.name, c.description],
      ];
      expect(texts, isNot(contains(startsWith('notifications.'))));
    }
  });

  testWidgets('channel names follow a language switch without a location', (
    tester,
  ) async {
    notifications = FakeNotificationService();
    final origin = tester.binding.clock.now();
    await pumpHayyaApp(
      tester,
      prefs: {'language_code': 'en'},
      notifications: notifications,
      location: FakeLocationService(
        results: [const LocationFailed(LocationFailure.unavailable)],
      ),
      now: () => midday.add(tester.binding.clock.now().difference(origin)),
    );
    expect(notifications.channels[NotificationSound.adhan]!.name, 'Adhan');

    await openSettings(tester, 'Settings');
    await tester.tap(find.text('العربية'));
    await settle(tester);

    expect(notifications.pending, isEmpty);
    expect(notifications.channels[NotificationSound.adhan]!.name, 'الأذان');
    expect(
      notifications.channels[NotificationSound.reminder]!.description,
      'نغمة هادئة قبل كل صلاة.',
    );
  });

  testWidgets('notification text follows a language switch', (tester) async {
    await pump(tester);
    await openSettings(tester, 'Settings');
    await tester.tap(find.text('العربية'));
    await settle(tester);

    expect(adhansNamed('حان الآن موعد صلاة الفجر'), hasLength(6));
    expect(notifications.pending.first.body, 'حيّ على الصلاة');
    expect(notifications.channels[NotificationSound.adhan]!.name, 'الأذان');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bell switches a prayer\'s adhan off and on', (tester) async {
    await pump(tester);
    final fajrBell = find.bySemanticsLabel('Adhan for Fajr');

    await tester.tap(fajrBell);
    await settle(tester, rounds: 2);
    expect(
      getIt<AdhanPreferencesRepository>().preferences.isEnabled(Prayer.fajr),
      isFalse,
    );
    expect(adhansNamed('It’s time for Fajr'), isEmpty);
    expect(adhansNamed('It’s time for Isha'), isNotEmpty);

    await tester.tap(fajrBell);
    await settle(tester, rounds: 2);
    expect(adhansNamed('It’s time for Fajr'), hasLength(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sunrise has no adhan bell to press', (tester) async {
    await pump(tester);
    final bell = tester.widget<AdhanToggle>(
      find.descendant(
        of: find.ancestor(
          of: find.text('Sunrise'),
          matching: find.byType(PrayerRow),
        ),
        matching: find.byType(AdhanToggle),
      ),
    );
    expect(bell.value, isFalse);
    expect(bell.onChanged, isNull);
  });

  testWidgets('first launch asks for notification permission once', (
    tester,
  ) async {
    await pump(tester, service: FakeNotificationService(allowed: false));
    expect(notifications.permissionRequests, 1);
    expect(find.text('Notifications are off'), findsNothing);
  });

  testWidgets('debug: "Test adhan in 1 minute" schedules one', (tester) async {
    await pump(tester);
    await openSettings(tester, 'Settings');
    await tapVisible(tester, find.text('Test adhan in 1 minute'));
    await settle(tester, rounds: 2);

    final test = notifications.pending.singleWhere(
      (n) => n.id == AdhanScheduler.testId,
    );
    expect(test.sound, NotificationSound.adhan);
    // The app clock moves with pumped time, so allow a few seconds.
    final delay = test.at.difference(midday);
    expect(delay, greaterThanOrEqualTo(const Duration(minutes: 1)));
    expect(delay, lessThan(const Duration(minutes: 1, seconds: 30)));
    expect(test.title, startsWith('It’s time for'));
    expect(find.textContaining('Test adhan scheduled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('settings', () {
    testWidgets('pre-adhan reminder: off by default, then 15 minutes', (
      tester,
    ) async {
      await pump(tester);
      await openSettings(tester, 'Settings');

      expect(find.text('Pre-adhan reminder'), findsOneWidget);
      expect(find.text('10 min'), findsNothing);

      await tapVisible(
        tester,
        find.descendant(
          of: find.byType(NotificationSettingsGroup),
          matching: find.byType(HayyaSwitch),
        ),
      );
      await settle(tester, rounds: 2);
      for (final label in ['5 min', '10 min', '15 min', '30 min']) {
        expect(find.text(label), findsOneWidget);
      }

      await tapVisible(tester, find.text('15 min'));
      await settle(tester, rounds: 2);
      final reminder = notifications.pending.firstWhere(
        (n) => n.sound == NotificationSound.reminder,
      );
      expect(reminder.title, 'Asr in 15 minutes');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic reminder uses Arabic digits and plural', (
      tester,
    ) async {
      await pump(tester, lang: 'ar');
      await openSettings(tester, 'الإعدادات');
      await tapVisible(
        tester,
        find.descendant(
          of: find.byType(NotificationSettingsGroup),
          matching: find.byType(HayyaSwitch),
        ),
      );
      await settle(tester, rounds: 2);

      expect(find.text('١٠ د'), findsOneWidget);
      final reminder = notifications.pending.firstWhere(
        (n) => n.sound == NotificationSound.reminder,
      );
      expect(reminder.title, 'بقيت ١٠ دقائق على أذان العصر');
      expect(tester.takeException(), isNull);
    });

    testWidgets('blocked notifications show a way to turn them on', (
      tester,
    ) async {
      await pump(
        tester,
        service: FakeNotificationService(allowed: false, grantOnRequest: false),
      );
      await openSettings(tester, 'Settings');

      expect(find.text('Notifications are off'), findsOneWidget);
      await tapVisible(tester, find.text('Turn on'));
      await settle(tester, rounds: 2);
      // Already prompted at first launch, so the settings open instead.
      expect(notifications.settingsOpened, 1);
    });

    testWidgets('missing exact alarms show a way to allow them', (
      tester,
    ) async {
      await pump(tester, service: FakeNotificationService(exact: false));
      await openSettings(tester, 'Settings');

      expect(find.text('The adhan may be late'), findsOneWidget);
      await tapVisible(tester, find.text('Allow'));
      await settle(tester, rounds: 2);
      expect(notifications.exactRequests, 1);
    });

    for (final (lang, size, label) in [
      ('en', phoneSize, 'Settings'),
      ('ar', phoneSize, 'الإعدادات'),
      ('en', const Size(320, 640), 'Settings'),
      ('ar', const Size(320, 640), 'الإعدادات'),
    ]) {
      testWidgets('lays out without overflow ($lang, ${size.width})', (
        tester,
      ) async {
        await pump(
          tester,
          lang: lang,
          size: size,
          service: FakeNotificationService(
            allowed: false,
            grantOnRequest: false,
          ),
        );
        await openSettings(tester, label);
        await tapVisible(
          tester,
          find.descendant(
            of: find.byType(NotificationSettingsGroup),
            matching: find.byType(HayyaSwitch),
          ),
        );
        await settle(tester, rounds: 2);
        await tester.ensureVisible(find.byType(NotificationSettingsGroup));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// Loads the real translations, but only once [gate] completes.
class _GatedLoader extends AssetLoader {
  final gate = Completer<void>();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    await gate.future;
    return const RootBundleAssetLoader().load(path, locale);
  }
}
