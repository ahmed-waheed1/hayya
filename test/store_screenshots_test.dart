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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hayya/core/router/app_router.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/presentation/home_screen.dart';
import 'package:hayya/core/widgets/widgets.dart';
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

/// [testWidgets] with real, blurred shadows. flutter_test draws them as
/// solid bands by default (`debugDisableShadows`) and checks after each
/// test that the flag is back, so it is restored before the test ends.
void _shot(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    final disabled = debugDisableShadows;
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = disabled;
    }
  });
}

/// Scrolls Settings so neither edge of the screen cuts a row in half,
/// in either column: no edge runs through a row, a picker, a button or
/// any text. Prefers the bottom edge falling between sections (the screen
/// ends after a whole section), and takes the smallest such scroll.
Future<void> _endOnWholeSection(WidgetTester tester) async {
  final list = find
      .descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  final position = tester.state<ScrollableState>(list).position;
  final view = tester.getRect(list);
  // Rects in scroll content coordinates.
  List<Rect> rects(Type type) => [
    for (final element
        in find.descendant(of: list, matching: find.byType(type)).evaluate())
      () {
        final box = element.renderObject! as RenderBox;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        return rect.shift(Offset(0, position.pixels - view.top));
      }(),
  ];
  final sections = rects(SettingsSection);
  final rows = [
    for (final type in [
      SettingsTile,
      SettingsPickerRow,
      SettingsStepperRow,
      SettingsRadioRow,
      AdaptiveRow,
      SegmentedPicker,
      HayyaButton,
    ])
      ...rects(type),
    // Text outside those rows (the location), with a little room.
    for (final r in rects(RichText)) r.inflate(2),
  ];
  bool through(double y, Iterable<Rect> rects) =>
      rects.any((r) => y > r.top + 1 && y < r.bottom - 1);
  bool clean(double y) => !through(y, rows);
  // Below a card (clear of most of its shadow), above the next header.
  bool betweenSections(double y) =>
      sections.every((r) => y <= r.top - 2 || y >= r.bottom + 4);

  final max = position.maxScrollExtent.floor();
  final offsets = [for (var o = 0; o <= max; o++) o.toDouble()];
  bool top(double o) => o == 0 || clean(o);
  final offset =
      offsets
          .where((o) => top(o) && betweenSections(o + view.height))
          .firstOrNull ??
      offsets.where((o) => top(o) && clean(o + view.height)).firstOrNull ??
      position.maxScrollExtent;
  position.jumpTo(offset);
  await tester.pump();
}

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
        _shot('01 home', (tester) async {
          await boot(tester);
          await shoot(tester, '01-home');
        });

        _shot('02 qibla', (tester) async {
          await qibla(tester, await boot(tester));
          await shoot(tester, '02-qibla');
        });

        _shot('03 tracker', (tester) async {
          await boot(tester);
          await go(tester, AppRoutes.tracker);
          await shoot(tester, '03-tracker');
        });

        _shot('04 timetable', (tester) async {
          await boot(tester);
          await go(tester, AppRoutes.timetable);
          await shoot(tester, '04-timetable');
        });

        _shot('05 settings', (tester) async {
          await boot(tester);
          await go(tester, AppRoutes.settings);
          await _endOnWholeSection(tester);
          await shoot(tester, '05-settings');
        });

        _shot('06 onboarding', (tester) async {
          await boot(tester, onboarding: true);
          await shoot(tester, '06-onboarding');
        });

        _shot('07 home dark', (tester) async {
          await boot(tester, theme: 'dark');
          await shoot(tester, '07-home-dark');
        });

        _shot('08 qibla dark', (tester) async {
          await qibla(tester, await boot(tester, theme: 'dark'));
          await shoot(tester, '08-qibla-dark');
        });
      });
    }
  }
}
