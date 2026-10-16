import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/di/injection.dart';
import 'package:hayya/core/preferences/app_preferences.dart';
import 'package:hayya/core/preferences/display_preferences.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/notification_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/core/utils/app_licenses.dart';
import 'package:hayya/core/utils/localized_format.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/notifications/domain/entities/adhan_preferences.dart';
import 'package:hayya/features/notifications/domain/repositories/adhan_preferences_repository.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/repositories/hijri_calendar_repository.dart';
import 'package:hayya/features/prayer_times/domain/repositories/prayer_settings_repository.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/home_header.dart';
import 'package:hayya/features/settings/presentation/widgets/location_group.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/fake_location_service.dart';
import '../../helpers/fake_notification_service.dart';
import '../../helpers/pump_app.dart';

const tabletPortrait = Size(834, 1194);
final midday = DateTime(2026, 10, 15, 13);
final today = DateTime(2026, 10, 15);
final tomorrow = DateTime(2026, 10, 16);

final oslo = UserLocation(
  coordinates: const GeoCoordinates(59.9139, 10.7522),
  updatedAt: DateTime(2026, 10, 15, 12),
  placeNames: const {
    'en': PlaceName(city: 'Oslo', country: 'Norway'),
    'ar': PlaceName(city: 'أوسلو', country: 'النرويج'),
  },
  countryCode: 'NO',
);

void main() {
  late FakeNotificationService notifications;
  late FakeLocationService location;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Hayya',
      packageName: 'app.hayya',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  /// Boots the app on Home at [midday] (moving with fake time), then
  /// opens Settings.
  Future<void> pumpSettings(
    WidgetTester tester, {
    String lang = 'en',
    Size size = phoneSize,
    Map<String, Object> prefs = const {},
    FakeLocationService? locationService,
    FakeNotificationService? notificationService,
  }) async {
    location =
        locationService ??
        FakeLocationService(
          lastKnown: alexandria,
          results: [LocationFound(alexandria)],
          places: [alexandria],
        );
    notifications = notificationService ?? FakeNotificationService();
    final origin = tester.binding.clock.now();
    await pumpHayyaApp(
      tester,
      size: size,
      prefs: {'language_code': lang, ...prefs},
      location: location,
      notifications: notifications,
      now: () => midday.add(tester.binding.clock.now().difference(origin)),
    );
    await goTo(tester, lang == 'ar' ? 'الإعدادات' : 'Settings');
  }

  /// A Home row's time text ("5:31").
  String homeTime(WidgetTester tester, Prayer prayer) => tester
      .widgetList<PrayerRow>(find.byType(PrayerRow))
      .elementAt(prayer.index)
      .time;

  /// What Home should show for [prayer] at [at] with [settings].
  String expectedTime(
    Prayer prayer,
    PrayerCalculationSettings settings, {
    GeoCoordinates? at,
    LocalizedFormat format = const LocalizedFormat(Locale('en')),
  }) => format
      .clock(
        const AdhanPrayerTimesRepository()
            .timesFor(today, at ?? alexandria.coordinates, settings)[prayer]
            .time,
      )
      .time;

  /// Tomorrow's first adhan for [prayer], as scheduled.
  ScheduledNotification adhanFor(String title) =>
      notifications.pending.firstWhere((n) => n.title == title);

  group('layout', () {
    for (final (sizeName, size) in [
      ('phone', phoneSize),
      ('small phone', const Size(320, 640)),
      ('tablet landscape', tabletSize),
      ('tablet portrait', tabletPortrait),
    ]) {
      for (final lang in ['en', 'ar']) {
        testWidgets('no overflow, everything showing ($sizeName · $lang)', (
          tester,
        ) async {
          await pumpSettings(
            tester,
            lang: lang,
            size: size,
            // Far north, so the high-latitude rule shows; notifications
            // blocked, so the warning shows; the reminder on.
            locationService: FakeLocationService(
              lastKnown: oslo,
              results: [LocationFound(oslo)],
              places: [alexandria, oslo],
            ),
            notificationService: FakeNotificationService(
              allowed: false,
              grantOnRequest: false,
            ),
            prefs: {
              'adhan_reminder_on': true,
              'adjustment_maghrib': -30,
              'hijri_adjustment_days': 2,
            },
          );
          expect(tester.takeException(), isNull);
          expect(
            find.text(lang == 'ar' ? 'منتصف الليل' : 'Middle of the night'),
            findsOneWidget,
          );

          // The manual search with results.
          await tapVisible(tester, find.text(lang == 'ar' ? 'يدوي' : 'Manual'));
          await settle(tester, rounds: 2);
          await tester.enterText(
            find.descendant(
              of: find.byType(LocationGroup),
              matching: find.byType(TextField),
            ),
            lang == 'ar' ? 'أوس' : 'Alex',
          );
          await settle(tester, rounds: 3);
          expect(tester.takeException(), isNull);

          // The method sheet.
          await tapVisible(
            tester,
            find.text(lang == 'ar' ? 'طريقة الحساب' : 'Calculation method'),
          );
          await settle(tester, rounds: 2);
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('two columns on a landscape tablet, one on a phone', (
      tester,
    ) async {
      Offset at(String text) => tester.getTopLeft(find.text(text));

      await pumpSettings(tester, size: tabletSize);
      expect(at('LOCATION').dx, greaterThan(at('GENERAL').dx + 200));
      expect(
        at('LOCATION').dy,
        lessThan(at('MANUAL ADJUSTMENTS (MINUTES)').dy),
      );

      await pumpSettings(tester);
      expect(at('LOCATION').dx, at('GENERAL').dx);
    });

    testWidgets('Arabic: columns mirror on a landscape tablet', (tester) async {
      await pumpSettings(tester, lang: 'ar', size: tabletSize);
      // The second column (Location) is on the left in RTL.
      expect(
        tester.getTopRight(find.text('الموقع')).dx,
        lessThan(tester.getTopRight(find.text('عام')).dx - 200),
      );
    });

    testWidgets('the high-latitude rule is hidden near the equator', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.text('High-latitude rule'), findsNothing);
    });
  });

  group('prayer times', () {
    testWidgets('a minute adjustment changes Home and the adhan', (
      tester,
    ) async {
      await pumpSettings(tester);
      final adhanBefore = adhanFor('It’s time for Fajr').at;

      for (var i = 0; i < 3; i++) {
        await tapVisible(
          tester,
          find.bySemanticsLabel('One minute later: Fajr'),
        );
        await tester.pump();
      }
      await tapVisible(
        tester,
        find.bySemanticsLabel('One minute earlier: Isha'),
      );
      await settle(tester, rounds: 2);

      expect(find.text('+3 min'), findsOneWidget);
      expect(find.text('−1 min'), findsOneWidget);
      final saved = getIt<PrayerSettingsRepository>().settings;
      expect(saved.adjustmentFor(Prayer.fajr), 3);
      expect(saved.adjustmentFor(Prayer.isha), -1);
      expect(
        adhanFor('It’s time for Fajr').at,
        adhanBefore.add(const Duration(minutes: 3)),
      );

      await goTo(tester, 'Home');
      expect(homeTime(tester, Prayer.fajr), expectedTime(Prayer.fajr, saved));
      expect(
        homeTime(tester, Prayer.fajr),
        isNot(expectedTime(Prayer.fajr, const PrayerCalculationSettings())),
      );
      expect(homeTime(tester, Prayer.isha), expectedTime(Prayer.isha, saved));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the steppers stop at ±30', (tester) async {
      await pumpSettings(tester, prefs: {'adjustment_dhuhr': 30});
      expect(find.text('+30 min'), findsOneWidget);
      InkWell button(String label) => tester.widget<InkWell>(
        find.descendant(
          of: find.bySemanticsLabel(label),
          matching: find.byType(InkWell),
        ),
      );
      expect(button('One minute later: Dhuhr').onTap, isNull);
      expect(button('One minute earlier: Dhuhr').onTap, isNotNull);
    });

    testWidgets('Hanafi Asr moves Home\'s Asr', (tester) async {
      await pumpSettings(tester);
      await tapVisible(tester, find.text('Hanafi'));
      await settle(tester, rounds: 2);

      final saved = getIt<PrayerSettingsRepository>().settings;
      expect(saved.madhab, AsrMadhab.hanafi);
      await goTo(tester, 'Home');
      expect(homeTime(tester, Prayer.asr), expectedTime(Prayer.asr, saved));
      expect(
        homeTime(tester, Prayer.asr),
        isNot(expectedTime(Prayer.asr, const PrayerCalculationSettings())),
      );
    });

    testWidgets('the method sheet suggests the country\'s method and saves '
        'the pick', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Egyptian General Authority of Survey'), findsOneWidget);

      await tapVisible(tester, find.text('Calculation method'));
      await settle(tester, rounds: 2);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Suggested for Egypt')),
        findsOneWidget,
      );
      // Every method is listed, with its angles.
      expect(
        find.descendant(
          of: sheet,
          matching: find.textContaining('Fajr 18.5°, Isha 90 minutes'),
        ),
        findsOneWidget,
      );

      await tapVisible(tester, find.text('Umm al-Qura University, Makkah'));
      await settle(tester, rounds: 2);

      expect(find.byType(BottomSheet), findsNothing);
      expect(
        getIt<PrayerSettingsRepository>().settings.method,
        CalculationMethod.ummAlQura,
      );
      expect(find.text('Umm al-Qura University, Makkah'), findsOneWidget);
      await goTo(tester, 'Home');
      expect(
        homeTime(tester, Prayer.isha),
        expectedTime(
          Prayer.isha,
          const PrayerCalculationSettings(method: CalculationMethod.ummAlQura),
        ),
      );
    });

    testWidgets('a far-north rule choice changes Fajr', (tester) async {
      await pumpSettings(
        tester,
        locationService: FakeLocationService(
          lastKnown: oslo,
          results: [LocationFound(oslo)],
        ),
      );
      await tapVisible(tester, find.text('Seventh of the night'));
      await settle(tester, rounds: 2);
      expect(
        getIt<PrayerSettingsRepository>().settings.highLatitudeRule,
        HighLatitudeRule.seventhOfTheNight,
      );
    });

    testWidgets('the Hijri adjustment changes Home\'s date', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Today: 4 Jumada al-Ula 1448 AH'), findsOneWidget);

      await tapVisible(tester, find.bySemanticsLabel('One day later'));
      await settle(tester, rounds: 2);

      expect(find.text('+1 day'), findsOneWidget);
      expect(find.text('Today: 5 Jumada al-Ula 1448 AH'), findsOneWidget);
      expect(getIt<HijriCalendarRepository>().adjustmentDays, 1);
      await goTo(tester, 'Home');
      expect(find.text('5 Jumada al-Ula 1448 AH'), findsOneWidget);
    });
  });

  group('display', () {
    testWidgets('Western numerals in Arabic reach Home and notifications', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        lang: 'ar',
        prefs: {'adhan_reminder_on': true},
      );
      const arabicIndic = LocalizedFormat(Locale('ar'));
      const western = LocalizedFormat(Locale('ar'), numerals: Numerals.western);
      final reminder = notifications.pending.firstWhere(
        (n) => n.sound == NotificationSound.reminder,
      );
      expect(reminder.title, contains('١٠'));

      await tapVisible(tester, find.text('123 غربية'));
      await settle(tester, rounds: 2);

      expect(
        getIt<AppPreferences>().displayPreferences.numerals,
        Numerals.western,
      );
      // Settings itself switches straight away.
      expect(find.text('0 د'), findsNWidgets(6));
      final rewritten = notifications.pending.firstWhere(
        (n) => n.sound == NotificationSound.reminder,
      );
      expect(rewritten.title, contains('10'));
      expect(rewritten.title, isNot(contains('١٠')));

      await goTo(tester, 'الرئيسية');
      const settings = PrayerCalculationSettings();
      expect(
        homeTime(tester, Prayer.fajr),
        expectedTime(Prayer.fajr, settings, format: western),
      );
      expect(
        homeTime(tester, Prayer.fajr),
        isNot(expectedTime(Prayer.fajr, settings, format: arabicIndic)),
      );
      final header = tester.widget<HomeHeader>(find.byType(HomeHeader));
      expect(header.hijriDate, startsWith('4 '));
    });

    testWidgets('the numerals choice is only offered in Arabic', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.text('Numerals'), findsNothing);
      await pumpSettings(tester, lang: 'ar');
      expect(find.text('الأرقام'), findsOneWidget);
    });

    testWidgets('24-hour time reaches Home', (tester) async {
      await pumpSettings(tester);
      // The device uses a 12-hour clock in tests, so that shows as chosen.
      expect(
        tester
            .widget<SegmentedPicker<TimeFormat>>(
              find.byType(SegmentedPicker<TimeFormat>),
            )
            .value,
        TimeFormat.twelveHour,
      );

      await tapVisible(tester, find.text('24-hour'));
      await settle(tester, rounds: 2);
      expect(
        getIt<AppPreferences>().displayPreferences.timeFormat,
        TimeFormat.twentyFourHour,
      );

      await goTo(tester, 'Home');
      const settings = PrayerCalculationSettings();
      expect(
        homeTime(tester, Prayer.maghrib),
        expectedTime(
          Prayer.maghrib,
          settings,
          format: const LocalizedFormat(Locale('en'), use24Hour: true),
        ),
      );
      expect(homeTime(tester, Prayer.maghrib), startsWith('1'));
      final maghrib = tester
          .widgetList<PrayerRow>(find.byType(PrayerRow))
          .elementAt(Prayer.maghrib.index);
      expect(maghrib.meridiem, isEmpty);
    });
  });

  group('adhan volume', () {
    testWidgets('notification volume moves the adhan to its channel', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(adhanFor('It’s time for Fajr').sound, NotificationSound.adhan);

      await tapVisible(tester, find.text('Notification volume'));
      await settle(tester, rounds: 2);

      expect(
        getIt<AdhanPreferencesRepository>().preferences.volume,
        AdhanVolume.notification,
      );
      expect(
        notifications.pending
            .where((n) => n.title.startsWith('It’s time for'))
            .every((n) => n.sound == NotificationSound.adhanNotificationVolume),
        isTrue,
      );
      expect(
        notifications.channels[NotificationSound.adhanNotificationVolume]!.name,
        'Adhan (notification volume)',
      );

      await tapVisible(tester, find.text('Alarm volume'));
      await settle(tester, rounds: 2);
      expect(adhanFor('It’s time for Fajr').sound, NotificationSound.adhan);
    });

    testWidgets('is not offered on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pumpSettings(tester);
      expect(find.text('Adhan volume'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('location', () {
    testWidgets('shows the current city and refreshes it', (tester) async {
      await pumpSettings(
        tester,
        locationService: FakeLocationService(
          lastKnown: alexandria,
          // Home's fix at start, then the refresh.
          results: [LocationFound(alexandria), LocationFound(cairo)],
        ),
      );
      expect(find.text('Alexandria, Egypt'), findsOneWidget);
      expect(find.textContaining('31.20°N 29.92°E'), findsOneWidget);

      final asked = location.permissionRequests.length;
      await tapVisible(tester, find.text('Update location'));
      await settle(tester, rounds: 2);
      expect(location.permissionRequests, hasLength(asked + 1));
      // The fake's device fix is Cairo.
      expect(find.text('Cairo, Egypt'), findsOneWidget);
    });

    testWidgets('a city chosen by search replaces GPS until Automatic', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        locationService: FakeLocationService(
          lastKnown: cairo,
          results: [LocationFound(cairo)],
          places: [alexandria],
        ),
      );
      final cairoFajr = adhanFor('It’s time for Fajr').at;

      await tapVisible(tester, find.text('Manual'));
      await settle(tester, rounds: 2);
      await tester.enterText(find.byType(TextField), 'Alex');
      await settle(tester, rounds: 3);
      expect(location.searches, ['Alex']);

      await tapVisible(tester, find.text('Alexandria'));
      await settle(tester, rounds: 2);

      expect(location.isManual, isTrue);
      expect(find.text('Alexandria, Egypt'), findsOneWidget);
      expect(find.textContaining('Chosen manually'), findsOneWidget);
      expect(adhanFor('It’s time for Fajr').at, isNot(cairoFajr));

      await goTo(tester, 'Home');
      expect(find.text('Alexandria'), findsOneWidget);
      expect(
        homeTime(tester, Prayer.fajr),
        expectedTime(Prayer.fajr, const PrayerCalculationSettings()),
      );

      await goTo(tester, 'Settings');
      await tapVisible(tester, find.text('Automatic'));
      await settle(tester, rounds: 2);
      expect(location.isManual, isFalse);
      expect(adhanFor('It’s time for Fajr').at, cairoFajr);
      await goTo(tester, 'Home');
      expect(find.text('Cairo'), findsOneWidget);
    });

    testWidgets('no match and a failed search say so', (tester) async {
      await pumpSettings(tester);
      await tapVisible(tester, find.text('Manual'));
      await settle(tester, rounds: 2);

      await tester.enterText(find.byType(TextField), 'Atlantis');
      await settle(tester, rounds: 3);
      expect(find.text('No cities match “Atlantis”.'), findsOneWidget);

      location.searchError = const PlaceSearchException('offline');
      await tester.enterText(find.byType(TextField), 'Atlantic');
      await settle(tester, rounds: 3);
      expect(find.textContaining('Couldn’t search'), findsOneWidget);
    });
  });

  group('about', () {
    testWidgets('shows the version and opens the licenses', (tester) async {
      registerAppLicenses();
      await pumpSettings(tester);
      await tester.ensureVisible(find.text('Version'));
      expect(find.text('1.0.0 (1)'), findsOneWidget);

      await tapVisible(tester, find.text('Licenses'));
      await settle(tester, rounds: 10);
      expect(find.byType(LicensePage), findsOneWidget);
      for (final name in ['Manrope', 'Cairo', adhanRecordingLicenseName]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    for (final (lang, title, url) in [
      (
        'en',
        'Privacy policy',
        'https://ahmed-waheed1.github.io/hayya-privacy/',
      ),
      (
        'ar',
        'سياسة الخصوصية',
        'https://ahmed-waheed1.github.io/hayya-privacy/ar.html',
      ),
    ]) {
      testWidgets('opens the privacy policy in the browser ($lang)', (
        tester,
      ) async {
        final launcher = FakeUrlLauncher();
        await pumpSettings(tester, lang: lang);
        await tapVisible(tester, find.text(title));
        await settle(tester, rounds: 2);
        expect(launcher.launched, [
          (url, PreferredLaunchMode.externalApplication),
        ]);
        expect(find.byType(SnackBar), findsNothing);
      });
    }

    testWidgets('shows the policy URL when no browser opens', (tester) async {
      FakeUrlLauncher(opens: false);
      await pumpSettings(tester);
      await tapVisible(tester, find.text('Privacy policy'));
      await settle(tester, rounds: 2);
      expect(
        find.text(
          'Couldn’t open the browser. The policy is at '
          'https://ahmed-waheed1.github.io/hayya-privacy/',
        ),
        findsOneWidget,
      );
    });
  });
}

/// Navigates with the bar or rail.
Future<void> goTo(WidgetTester tester, String label) async {
  final nav = find.byWidgetPredicate(
    (w) => w is HayyaNavBar || w is HayyaNavRail,
  );
  await tester.tap(find.descendant(of: nav, matching: find.text(label)));
  await settle(tester, rounds: 2);
}

/// Records what url_launcher was asked to open, and installs itself for
/// the current test.
class FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  FakeUrlLauncher({this.opens = true}) {
    final original = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = this;
    addTearDown(() => UrlLauncherPlatform.instance = original);
  }

  /// What [launchUrl] returns.
  final bool opens;

  final launched = <(String, PreferredLaunchMode)>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add((url, options.mode));
    return opens;
  }
}
