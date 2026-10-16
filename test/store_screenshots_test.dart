/// Google Play screenshots from the real app: the same widgets, fonts and
/// translations as the app, with fixed sample data. Skipped unless asked:
///
/// ```sh
/// TZ=Africa/Cairo flutter test test/store_screenshots_test.dart \
///   --dart-define=STORE_SCREENSHOTS=true
/// ```
///
/// Writes `store/screenshots/{en,ar}/{phone,tablet}/NN-name.png` (gitignored).
/// Play's rules: JPEG or 24-bit PNG without alpha, each side 320–3840 px,
/// the long side at most twice the short one; phone 9:16 at least
/// 1080 × 1920 and tablet 16:9 for promotion.
@Tags(['store-screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hayya/core/router/app_router.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/presentation/home_screen.dart';
import 'package:hayya/features/qibla/domain/compass_sensor.dart';
import 'package:hayya/features/settings/presentation/settings_screen.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';

import 'helpers/fake_compass_sensor.dart';
import 'helpers/fake_location_service.dart';
import 'helpers/pump_app.dart';

const _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');

/// Cairo's Qibla bearing from true north.
const _cairoBearing = 136.137;

/// A store device: its pixel size and the density it renders at.
typedef _Device = ({String name, ui.Size pixels, double ratio});

const _devices = <_Device>[
  // 9:16, 392 × 698 logical: a typical phone.
  (name: 'phone', pixels: ui.Size(1080, 1920), ratio: 2.75),
  // 16:9 landscape, 1280 × 720 logical: a 10-inch tablet.
  (name: 'tablet', pixels: ui.Size(2560, 1440), ratio: 2),
];

/// Twenty minutes before Asr in Cairo on 15 October 2026, with the
/// default calculation settings, so Home counts down to Asr.
final DateTime _moment = () {
  final day = const AdhanPrayerTimesRepository().timesFor(
    DateTime(2026, 10, 15),
    cairo.coordinates,
    const PrayerCalculationSettings(),
  );
  final asr = day.times.firstWhere((t) => t.prayer == Prayer.asr).time;
  return asr.subtract(const Duration(minutes: 20));
}();

String _dayKey(DateTime day) =>
    'day:${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// 34 weeks of mostly complete days with scattered gaps (enough to fill the
/// tablet heatmap), the last 23 in a row, with Fajr and Dhuhr prayed today
/// and a little qada left.
Map<String, Object> _tracker() {
  final today = DateTime(2026, 10, 15);
  DateTime ago(int days) => DateTime(today.year, today.month, today.day - days);
  // Bits: Fajr, Dhuhr, Asr, Maghrib, Isha.
  const all = 0x1F;
  const days = 34 * 7;
  // Incomplete days: one or two prayers missed, most often Fajr.
  const gaps = [0x1E, 0x1D, 0x1E, 0x0F, 0x17, 0x1E, 0x1B, 0x0E];
  // Day 24 ends the streak; after it, gaps on two cycles that don't line
  // up with the week, so they scatter across the heatmap.
  bool gap(int i) => i == 24 || (i > 24 && (i % 11 == 0 || i % 13 == 6));
  return {
    'since': _dayKey(ago(days)).substring('day:'.length),
    for (var i = 1; i <= days; i++)
      _dayKey(ago(i)): gap(i) ? gaps[i % gaps.length] : all,
    _dayKey(today): 0x03,
    'qada:fajr': 2,
    'qada:isha': 1,
    'qada_made_up': 6,
  };
}

/// Renders the whole view at its physical size and saves it as an RGB PNG.
Future<void> _save(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final image = await captureImage(tester.binding.rootElement!);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bytes!.buffer,
      numChannels: 4,
    );
    // Play wants 24-bit PNGs: drop the alpha channel.
    final rgb = rgba.convert(numChannels: 3);
    final file = File(path)..parent.createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(rgb));
    image.dispose();
  });
}

void main() {
  group('store screenshots', skip: _enabled ? false : _skipReason, () {
    _screenshots();
  });
}

const _skipReason =
    'Run with --dart-define=STORE_SCREENSHOTS=true to write store screenshots';

void _screenshots() {
  setUpAll(() {
    showDeveloperTools = false;
    // Settings → About shows the version from pubspec.yaml ("1.0.0+1").
    final version = RegExp(
      r'^version: (\S+?)\+(\S+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!;
    PackageInfo.setMockInitialValues(
      appName: 'Hayya',
      packageName: 'com.ahmedwaheed.hayya',
      version: version[1]!,
      buildNumber: version[2]!,
      buildSignature: '',
    );
  });
  tearDownAll(() => showDeveloperTools = true);

  for (final device in _devices) {
    for (final lang in ['en', 'ar']) {
      final dir = 'store/screenshots/$lang/${device.name}';

      /// Boots the app on Home with the sample data.
      Future<FakeCompassSensor> boot(
        WidgetTester tester, {
        String theme = 'light',
        bool onboarding = false,
      }) async {
        final compass = FakeCompassSensor(north: NorthReference.trueNorth);
        await pumpHayyaApp(
          tester,
          size: device.pixels / device.ratio,
          prefs: {'language_code': lang, 'theme_mode': theme},
          now: () => _moment,
          compass: compass,
          tracker: _tracker(),
          onboarding: onboarding,
          // Onboarding only shows while no location is known.
          location: onboarding ? FakeLocationService() : null,
        );
        // pumpHayyaApp renders at ratio 1; switch to the store density.
        tester.view
          ..physicalSize = device.pixels
          ..devicePixelRatio = device.ratio;
        await settle(tester, rounds: 3);
        return compass;
      }

      Future<void> go(WidgetTester tester, String route) async {
        GoRouter.of(tester.element(find.byType(HomeScreen))).go(route);
        await settle(tester, rounds: 4);
      }

      Future<void> shoot(WidgetTester tester, String name) async {
        expect(tester.takeException(), isNull);
        await _save(tester, '$dir/$name.png');
      }

      Future<void> qibla(WidgetTester tester, FakeCompassSensor compass) async {
        await go(tester, AppRoutes.qibla);
        compass.sendLive(_cairoBearing, accuracy: CompassAccuracy.high);
        await tester.pump(const Duration(milliseconds: 300));
        await settle(tester, rounds: 4);
      }

      group('${device.name} $lang', () {
        testWidgets('01 home', (tester) async {
          await boot(tester);
          await shoot(tester, '01-home');
        });

        testWidgets('02 qibla', (tester) async {
          await qibla(tester, await boot(tester));
          await shoot(tester, '02-qibla');
        });

        testWidgets('03 tracker', (tester) async {
          await boot(tester);
          await go(tester, AppRoutes.tracker);
          await shoot(tester, '03-tracker');
        });

        testWidgets('04 timetable', (tester) async {
          await boot(tester);
          await go(tester, AppRoutes.timetable);
          await shoot(tester, '04-timetable');
        });

        testWidgets('05 settings', (tester) async {
          await boot(tester);
          await go(tester, AppRoutes.settings);
          await shoot(tester, '05-settings');
        });

        testWidgets('06 onboarding', (tester) async {
          await boot(tester, onboarding: true);
          await shoot(tester, '06-onboarding');
        });

        testWidgets('07 home dark', (tester) async {
          await boot(tester, theme: 'dark');
          await shoot(tester, '07-home-dark');
        });

        testWidgets('08 qibla dark', (tester) async {
          await qibla(tester, await boot(tester, theme: 'dark'));
          await shoot(tester, '08-qibla-dark');
        });
      });
    }
  }
}
