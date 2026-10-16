// Every screen and state at 1.0x–2.0x text, in both languages, on five
// screen sizes: nothing overflows, is cut off or is shrunk below its 1.0x
// size. Add each new screen here.
//
// Run with --dart-define=PROBE=true to print every issue instead of
// failing on the first.
//
// Tagged so day-to-day runs can skip it: flutter test --exclude-tags
// text-scale. The full suite runs it (see docs/conventions.md).
@Tags(['text-scale'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hayya/core/router/app_router.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/onboarding/presentation/onboarding_screen.dart';
import 'package:hayya/features/prayer_times/presentation/home_screen.dart';
import 'package:hayya/features/qibla/domain/compass_sensor.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/timetable_link.dart';
import 'package:hayya/features/settings/presentation/settings_screen.dart';
import 'package:hayya/features/settings/presentation/widgets/location_group.dart';
import 'package:hayya/features/timetable/presentation/timetable_screen.dart';
import 'package:hayya/features/tracker/presentation/tracker_screen.dart';
import 'package:hayya/features/tracker/presentation/widgets/prayer_heatmap.dart';

import 'helpers/fake_compass_sensor.dart';
import 'helpers/fake_location_service.dart';
import 'helpers/fake_notification_service.dart';
import 'helpers/pump_app.dart';
import 'helpers/text_scale.dart';

const probe = bool.fromEnvironment('PROBE');

/// Maghrib is current on Home: the longest name, with the NOW badge.
final evening = DateTime(2026, 10, 15, 18, 30);

/// Far north, so Settings shows the high-latitude rule.
final oslo = UserLocation(
  coordinates: const GeoCoordinates(59.9139, 10.7522),
  updatedAt: DateTime(2026, 10, 15, 12),
  placeNames: const {
    'en': PlaceName(city: 'Oslo', country: 'Norway'),
    'ar': PlaceName(city: 'أوسلو', country: 'النرويج'),
  },
  countryCode: 'NO',
);

/// Checks what's on screen now; [state] names it in failures.
Future<void> check(WidgetTester tester, TextScaleCase c, String state) async {
  if (!probe) {
    expect(tester.takeException(), isNull, reason: state);
    final issues = readabilityIssues(tester, scale: c.scale);
    expect(issues, isEmpty, reason: '$state:\n${issues.join('\n')}');
    return;
  }
  final error = tester.takeException();
  final issues = [
    if (error != null) 'exception: ${'$error'.split('\n').first}',
    ...readabilityIssues(tester, scale: c.scale),
  ];
  for (final issue in issues) {
    debugPrint('ISSUE | ${c.sizeName} ${c.lang} ${c.scale}x | $state | $issue');
  }
}

/// Scrolls [scrollable] to the end in steps, checking at each.
Future<void> checkScrolling(
  WidgetTester tester,
  TextScaleCase c,
  String state,
  Finder scrollable,
) async {
  await check(tester, c, state);
  for (var i = 0; i < 20; i++) {
    final position = tester.state<ScrollableState>(scrollable).position;
    if (position.pixels >= position.maxScrollExtent) break;
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pump();
    await check(tester, c, '$state (scrolled)');
  }
}

Finder mainScrollable(Type screen) => find
    .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
    .first;

Future<void> pumpAt(
  WidgetTester tester,
  TextScaleCase c, {
  LocationService? location,
  FakeNotificationService? notifications,
  FakeCompassSensor? compass,
  Map<String, Object> prefs = const {},
  Map<String, Object> tracker = const {},
  bool onboarding = false,
}) => pumpHayyaApp(
  tester,
  size: c.size,
  prefs: {'language_code': c.lang, ...prefs},
  now: () => evening,
  location: location,
  notifications: notifications,
  compass: compass,
  tracker: tracker,
  onboarding: onboarding,
);

Future<void> goTab(WidgetTester tester, String en, String ar, String lang) =>
    tapNav(tester, lang == 'ar' ? ar : en);

Future<void> tapNav(WidgetTester tester, String label) async {
  final nav = find.byWidgetPredicate(
    (w) => w is HayyaNavBar || w is HayyaNavRail,
  );
  await tester.tap(find.descendant(of: nav, matching: find.text(label)));
  await settle(tester, rounds: 2);
}

String key(DateTime day) =>
    'day:${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Forty days of history with gaps and something to make up.
Map<String, Object> history() {
  final today = DateTime(2026, 10, 15);
  DateTime ago(int days) => DateTime(today.year, today.month, today.day - days);
  return {
    'since': '2026-09-05',
    for (var i = 1; i <= 12; i++) key(ago(i)): 0x1F,
    key(ago(13)): 0x1E,
    for (var i = 14; i <= 30; i++) key(ago(i)): i.isEven ? 0x1F : 0x0E,
    key(today): 0x03,
    'qada:fajr': 9,
    'qada:dhuhr': 3,
    'qada:asr': 4,
    'qada:maghrib': 2,
    'qada:isha': 5,
  };
}

Future<void> tapText(WidgetTester tester, String en, String ar, String lang) =>
    tapVisible(tester, find.text(lang == 'ar' ? ar : en));

/// Simulates coming back from the system settings.
Future<void> resume(WidgetTester tester) async {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await settle(tester, rounds: 2);
}

void main() {
  textScaleMatrix('Onboarding', (tester, c) async {
    await pumpAt(
      tester,
      c,
      onboarding: true,
      // Each failure in turn, then found.
      location: FakeLocationService(
        results: const [
          LocationFailed(LocationFailure.permissionDenied),
          LocationFailed(LocationFailure.permissionDeniedForever),
          LocationFailed(LocationFailure.serviceDisabled),
          LocationFailed(LocationFailure.unavailable),
        ].cast<LocationResult>().followedBy([LocationFound(cairo)]).toList(),
        places: [alexandria],
      ),
      notifications: FakeNotificationService(
        allowed: false,
        grantOnRequest: false,
      ),
    );
    final scrollable = mainScrollable(OnboardingScreen);
    await checkScrolling(tester, c, 'welcome', scrollable);

    await tapText(tester, 'Get started', 'ابدأ الآن', c.lang);
    await settle(tester, rounds: 2);
    await checkScrolling(tester, c, 'location', scrollable);

    // The city sheet with results; closed without choosing.
    await tapText(
      tester,
      'Choose a city manually',
      'اختيار مدينة يدويًا',
      c.lang,
    );
    await settle(tester, rounds: 2);
    await tester.enterText(
      find.byType(TextField),
      c.lang == 'ar' ? 'الإس' : 'Alex',
    );
    await settle(tester, rounds: 3);
    await check(tester, c, 'city sheet');
    Navigator.of(tester.element(find.byType(TextField))).pop();
    await settle(tester, rounds: 2);

    await tapText(tester, 'Allow location', 'السماح بالموقع', c.lang);
    await settle(tester, rounds: 2);
    await checkScrolling(tester, c, 'location denied', scrollable);
    for (final (state, link, arLink) in [
      ('blocked', 'Open Settings', 'فتح الإعدادات'),
      ('off', 'Location settings', 'إعدادات الموقع'),
      ('unavailable', 'Try again', 'حاول مرة أخرى'),
    ]) {
      await resume(tester);
      expect(find.text(c.lang == 'ar' ? arLink : link), findsOneWidget);
      await checkScrolling(tester, c, 'location $state', scrollable);
    }
    await tapText(tester, 'Try again', 'حاول مرة أخرى', c.lang);
    await settle(tester, rounds: 2);
    await checkScrolling(tester, c, 'notifications', scrollable);

    final back = find.bySemanticsLabel(c.lang == 'ar' ? 'رجوع' : 'Back');
    await Scrollable.ensureVisible(tester.element(back), alignment: 0.5);
    await tester.pump();
    await tester.tap(back);
    await settle(tester, rounds: 2);
    await checkScrolling(tester, c, 'location found', scrollable);
    await tapText(tester, 'Continue', 'متابعة', c.lang);
    await settle(tester, rounds: 2);

    await tapText(tester, 'Allow notifications', 'السماح بالإشعارات', c.lang);
    await settle(tester, rounds: 2);
    expect(find.text(c.lang == 'ar' ? 'متابعة' : 'Continue'), findsOneWidget);
    await checkScrolling(tester, c, 'notifications denied', scrollable);
  });

  textScaleMatrix('Home', (tester, c) async {
    await pumpAt(tester, c);
    await checkScrolling(tester, c, 'home', mainScrollable(HomeScreen));

    // At 1.0x each time sits beside its prayer's name, as designed.
    if (c.scale == 1.0) {
      for (final row in tester.widgetList<PrayerRow>(find.byType(PrayerRow))) {
        final rowFinder = find.byWidget(row);
        final name = find.descendant(
          of: rowFinder,
          matching: find.text(row.name),
        );
        final time = find.descendant(
          of: rowFinder,
          matching: find.textContaining(row.time, findRichText: true),
        );
        expect(
          tester.getRect(time).top,
          lessThan(tester.getRect(name).bottom),
          reason: '${row.name}: time wrapped under the name at 1.0x',
        );
      }
    }
  });

  textScaleMatrix('Settings', (tester, c) async {
    await pumpAt(
      tester,
      c,
      // Far north (high-latitude rule), notifications blocked (warning),
      // reminder on, adjustments set: every optional row shows.
      location: FakeLocationService(
        lastKnown: oslo,
        results: [LocationFound(oslo)],
        places: [alexandria, oslo],
      ),
      notifications: FakeNotificationService(
        allowed: false,
        grantOnRequest: false,
      ),
      prefs: {
        'adhan_reminder_on': true,
        'adjustment_maghrib': -30,
        'hijri_adjustment_days': 2,
      },
    );
    await goTab(tester, 'Settings', 'الإعدادات', c.lang);
    final scrollable = mainScrollable(SettingsScreen);
    await checkScrolling(tester, c, 'settings', scrollable);

    // City search with results.
    final manual = find.text(c.lang == 'ar' ? 'يدوي' : 'Manual');
    await Scrollable.ensureVisible(tester.element(manual), alignment: 0.5);
    await tester.pump();
    await tester.tap(manual);
    await settle(tester, rounds: 2);
    await tester.enterText(
      find.descendant(
        of: find.byType(LocationGroup),
        matching: find.byType(TextField),
      ),
      c.lang == 'ar' ? 'أوس' : 'Alex',
    );
    await settle(tester, rounds: 3);
    await tester.ensureVisible(find.byType(LocationGroup));
    await tester.pump();
    await check(tester, c, 'city search');

    // The calculation method sheet, scrolled through.
    await tapVisible(
      tester,
      find.text(c.lang == 'ar' ? 'طريقة الحساب' : 'Calculation method'),
    );
    await settle(tester, rounds: 2);
    expect(find.byType(BottomSheet), findsOneWidget);
    await checkScrolling(
      tester,
      c,
      'method sheet',
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  });

  textScaleMatrix('Qibla', (tester, c) async {
    final compass = FakeCompassSensor();
    await pumpAt(tester, c, compass: compass);
    await goTab(tester, 'Qibla', 'القبلة', c.lang);
    await check(tester, c, 'checking');

    await tester.pump(const Duration(seconds: 4));
    await check(tester, c, 'no sensor');

    await tapVisible(
      tester,
      find.text(c.lang == 'ar' ? 'إعادة المحاولة' : 'Retry'),
    );
    await tester.pump();
    compass.sendLive(113, accuracy: CompassAccuracy.high);
    await tester.pump(const Duration(milliseconds: 300));
    await check(tester, c, 'seeking');

    compass.sendLive(136.137, accuracy: CompassAccuracy.high);
    await tester.pump(const Duration(milliseconds: 300));
    await check(tester, c, 'aligned');

    compass
      ..sendLive(80, accuracy: CompassAccuracy.high)
      ..send(80, accuracy: CompassAccuracy.low);
    await tester.pump(const Duration(milliseconds: 300));
    await check(tester, c, 'calibrating');
  });

  textScaleMatrix('Qibla without a location', (tester, c) async {
    await pumpAt(
      tester,
      c,
      location: FakeLocationService(
        results: [const LocationFailed(LocationFailure.serviceDisabled)],
      ),
    );
    await goTab(tester, 'Qibla', 'القبلة', c.lang);
    await check(tester, c, 'location error');
  });

  textScaleMatrix('Tracker, new', (tester, c) async {
    await pumpAt(tester, c, tracker: {'since': '2026-10-15'});
    GoRouter.of(tester.element(find.byType(HomeScreen))).go(AppRoutes.tracker);
    await settle(tester, rounds: 3);
    await checkScrolling(
      tester,
      c,
      'tracker new',
      mainScrollable(TrackerScreen),
    );
  });

  textScaleMatrix('Tracker, history', (tester, c) async {
    await pumpAt(tester, c, tracker: history());
    GoRouter.of(tester.element(find.byType(HomeScreen))).go(AppRoutes.tracker);
    await settle(tester, rounds: 3);
    await checkScrolling(
      tester,
      c,
      'tracker history',
      mainScrollable(TrackerScreen),
    );

    // The day sheet for a past day.
    final grid = find.byKey(PrayerHeatmap.gridKey);
    await tester.ensureVisible(grid);
    await tester.pump();
    final heatmap = tester.widget<PrayerHeatmap>(find.byType(PrayerHeatmap));
    final cell = heatmap.cellRect(
      DateTime(2026, 10, 14),
      Directionality.of(tester.element(grid)),
    );
    await tester.tapAt(tester.getTopLeft(grid) + cell.center);
    await settle(tester, rounds: 2);
    expect(find.byType(BottomSheet), findsOneWidget);
    await check(tester, c, 'day sheet');
    Navigator.of(tester.element(find.byType(PrayedCheck).first)).pop();
    await settle(tester, rounds: 2);

    // Editing what's owed.
    await tapVisible(
      tester,
      find.text(c.lang == 'ar' ? 'تعديل العدد' : 'Edit counts'),
    );
    await settle(tester, rounds: 2);
    expect(find.byType(TextField), findsNWidgets(5));
    await check(tester, c, 'qada sheet');
  });

  textScaleMatrix('Timetable', (tester, c) async {
    await pumpAt(tester, c);
    await tapVisible(tester, find.byType(TimetableLink));
    await settle(tester, rounds: 3);
    expect(find.byType(TimetableScreen), findsOneWidget);
    await checkScrolling(
      tester,
      c,
      'timetable',
      mainScrollable(TimetableScreen),
    );
  });
}
