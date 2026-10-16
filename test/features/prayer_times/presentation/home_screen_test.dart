import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/home_skeleton.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/location_status_view.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/next_prayer_card.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/prayer_list.dart';

import '../../../helpers/fake_location_service.dart';
import '../../../helpers/pump_app.dart';

const tabletPortrait = Size(834, 1194);

/// Midday (Dhuhr), night (Isha, next Fajr tomorrow) and dawn (Fajr).
final midday = DateTime(2026, 10, 15, 13);
final night = DateTime(2026, 10, 15, 22);
final dawn = DateTime(2026, 10, 15, 5, 45);

PrayerSchedule expectedAt(DateTime now) =>
    GetPrayerSchedule(const AdhanPrayerTimesRepository())(
      now: now,
      coordinates: cairo.coordinates,
      settings: const PrayerCalculationSettings(),
    );

/// Boots the app with Home's clock starting at [start] and advancing with
/// the test's fake time.
Future<void> pumpHome(
  WidgetTester tester, {
  DateTime? start,
  String lang = 'en',
  String theme = 'light',
  Size size = phoneSize,
  LocationService? location,
}) async {
  final origin = tester.binding.clock.now();
  final base = start ?? midday;
  await pumpHayyaApp(
    tester,
    size: size,
    prefs: {'language_code': lang, 'theme_mode': theme},
    location: location,
    now: () => base.add(tester.binding.clock.now().difference(origin)),
  );
}

void main() {
  group('ready', () {
    testWidgets('shows the next prayer, the city, dates and today\'s list', (
      tester,
    ) async {
      await pumpHome(tester);
      final expected = expectedAt(midday);

      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('NEXT PRAYER'), findsOneWidget);
      expect(find.text('Thursday, 15 October 2026'), findsOneWidget);
      expect(find.text('4 Jumada al-Ula 1448 AH'), findsOneWidget);
      expect(find.byType(PrayerRow), findsNWidgets(6));
      expect(find.text('NOW'), findsOneWidget);
      final nextName = expected.next.prayer.name;
      expect(
        find.descendant(
          of: find.byType(NextPrayerCard),
          matching: find.textContaining(
            nextName[0].toUpperCase() + nextName.substring(1),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the countdown ticks', (tester) async {
      await pumpHome(tester);
      String countdown() => tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(NextPrayerCard),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .firstWhere(
            (s) => s != null && RegExp(r'^\d\d:\d\d:\d\d$').hasMatch(s),
          )!;

      final before = countdown();
      await tester.pump(const Duration(seconds: 1));
      final after = countdown();
      expect(after, isNot(before));
    });

    testWidgets('after Isha, Fajr is marked tomorrow', (tester) async {
      await pumpHome(tester, start: night);
      expect(expectedAt(night).nextIsTomorrow, isTrue);
      expect(find.textContaining('tomorrow'), findsOneWidget);
    });

    testWidgets('Arabic: RTL, Arabic-Indic digits, Arabic city', (
      tester,
    ) async {
      await pumpHome(tester, lang: 'ar');
      expect(find.text('القاهرة'), findsOneWidget);
      expect(find.text('الخميس، ١٥ أكتوبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('٤ جمادى الأولى ١٤٤٨ هـ'), findsOneWidget);
      expect(find.text('الآن'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(NextPrayerCard))),
        TextDirection.rtl,
      );
      expect(find.textContaining(RegExp('[0-9]')), findsNothing);
    });

    testWidgets('tablet shows the Qibla chip and large rows side by side', (
      tester,
    ) async {
      await pumpHome(tester, size: tabletSize);
      expect(find.text('Qibla 136° SE'), findsOneWidget);
      final hero = tester.getRect(find.byType(NextPrayerCard));
      final list = tester.getRect(find.byType(PrayerList));
      expect(list.left, greaterThan(hero.right));
      expect(list.top, hero.top);
      expect(list.height, hero.height);
      expect(tester.getSize(find.byType(PrayerRow).first).height, 76);
    });

    testWidgets('tablet portrait stacks the list under the hero', (
      tester,
    ) async {
      await pumpHome(tester, size: tabletPortrait);
      final hero = tester.getRect(find.byType(NextPrayerCard));
      final list = tester.getRect(find.byType(PrayerList));
      expect(list.top, greaterThan(hero.bottom));
      expect(tester.takeException(), isNull);
    });
  });

  group('no overflow', () {
    for (final (sizeName, size) in [
      ('phone', phoneSize),
      ('small phone', const Size(320, 640)),
      ('tablet', tabletSize),
      ('tablet portrait', tabletPortrait),
    ]) {
      for (final lang in ['en', 'ar']) {
        for (final (timeName, time) in [
          ('midday', midday),
          ('night', night),
          ('dawn', dawn),
        ]) {
          testWidgets('$sizeName · $lang · $timeName', (tester) async {
            await pumpHome(
              tester,
              size: size,
              lang: lang,
              start: time,
              theme: time == night ? 'dark' : 'light',
            );
            expect(find.byType(NextPrayerCard), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    testWidgets('large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpHome(tester, lang: 'ar');
      expect(tester.takeException(), isNull);
    });
  });

  group('loading', () {
    for (final (name, size) in [('phone', phoneSize), ('tablet', tabletSize)]) {
      testWidgets('skeleton until the first location ($name)', (tester) async {
        final location = FakeLocationService()..gate = Completer();
        await pumpHome(tester, size: size, location: location);

        expect(find.byType(SkeletonHeroCard), findsOneWidget);
        expect(find.byType(NextPrayerCard), findsNothing);
        expect(tester.takeException(), isNull);

        location.gate!.complete();
        await settle(tester, rounds: 2);
        expect(find.byType(SkeletonHeroCard), findsNothing);
        expect(find.byType(NextPrayerCard), findsOneWidget);
      });
    }
  });

  group('location denied', () {
    testWidgets('asks again with Allow location', (tester) async {
      final location = FakeLocationService(
        results: [
          const LocationFailed(LocationFailure.permissionDenied),
          LocationFound(cairo),
        ],
      );
      await pumpHome(tester, location: location);

      expect(find.text('Location access is off'), findsOneWidget);
      await tester.tap(find.text('Allow location'));
      await settle(tester, rounds: 2);

      expect(location.permissionRequests, [false, true]);
      expect(find.byType(NextPrayerCard), findsOneWidget);
    });

    testWidgets('denied for good opens the app settings', (tester) async {
      final location = FakeLocationService(
        results: [
          const LocationFailed(LocationFailure.permissionDeniedForever),
        ],
      );
      await pumpHome(tester, location: location, lang: 'ar');

      expect(find.text('الوصول إلى الموقع متوقف'), findsOneWidget);
      await tester.tap(find.text('فتح الإعدادات'));
      await settle(tester, rounds: 1);
      expect(location.appSettingsOpened, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('GPS off', () {
    testWidgets('without a cache: try again or open location settings', (
      tester,
    ) async {
      final location = FakeLocationService(
        results: [const LocationFailed(LocationFailure.serviceDisabled)],
      );
      await pumpHome(tester, location: location);

      expect(find.text('Can’t find your location'), findsOneWidget);
      expect(find.text('Use last location'), findsNothing);
      await tester.tap(find.text('Location settings'));
      await settle(tester, rounds: 1);
      expect(location.locationSettingsOpened, 1);
    });

    testWidgets('after an update attempt: offers the last location', (
      tester,
    ) async {
      final location = FakeLocationService(
        lastKnown: cairo,
        results: [const LocationFailed(LocationFailure.serviceDisabled)],
      );
      await pumpHome(tester, location: location);

      // The silent refresh at launch failed; the cached times stay.
      expect(find.byType(NextPrayerCard), findsOneWidget);

      await tester.tap(find.text('Cairo'));
      await settle(tester, rounds: 2);
      expect(find.text('Can’t find your location'), findsOneWidget);
      expect(find.text('Cairo, Egypt'), findsOneWidget);
      expect(find.textContaining('Last updated'), findsOneWidget);

      await tester.tap(find.text('Use last location'));
      await settle(tester, rounds: 2);
      expect(find.byType(NextPrayerCard), findsOneWidget);
    });

    for (final (name, size) in [
      ('phone', phoneSize),
      ('small phone', const Size(320, 640)),
      ('tablet', tabletSize),
    ]) {
      for (final lang in ['en', 'ar']) {
        testWidgets('no overflow ($name · $lang)', (tester) async {
          final location = FakeLocationService(
            lastKnown: cairo,
            results: [const LocationFailed(LocationFailure.unavailable)],
          );
          await pumpHome(tester, location: location, size: size, lang: lang);
          await tester.tap(find.text(lang == 'ar' ? 'القاهرة' : 'Cairo'));
          await settle(tester, rounds: 2);
          expect(find.byType(LocationStatusView), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
