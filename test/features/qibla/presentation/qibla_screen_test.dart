import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/location_status_view.dart';
import 'package:hayya/features/qibla/domain/compass_sensor.dart';
import 'package:hayya/features/qibla/presentation/qibla_screen.dart';
import 'package:hayya/features/qibla/presentation/widgets/compass_help_cards.dart';
import 'package:hayya/features/qibla/presentation/widgets/qibla_dial.dart';
import 'package:hayya/features/qibla/presentation/widgets/qibla_stats.dart';

import '../../../helpers/fake_compass_sensor.dart';
import '../../../helpers/fake_location_service.dart';
import '../../../helpers/pump_app.dart';

const tabletPortrait = Size(834, 1194);

/// Cairo's Qibla, rounded.
const cairoBearing = 136.137;

enum Scene { checking, seeking, aligned, calibrating, noSensor }

void main() {
  late FakeCompassSensor compass;

  /// Boots the app and opens the Qibla tab.
  Future<void> pumpQibla(
    WidgetTester tester, {
    String lang = 'en',
    String theme = 'light',
    Size size = phoneSize,
    LocationService? location,
  }) async {
    compass = FakeCompassSensor();
    await pumpHayyaApp(
      tester,
      size: size,
      prefs: {'language_code': lang, 'theme_mode': theme},
      location: location,
      compass: compass,
    );
    await tapNav(tester, lang == 'ar' ? 'القبلة' : 'Qibla');
  }

  /// Drives the fake compass into [scene].
  Future<void> show(WidgetTester tester, Scene scene) async {
    switch (scene) {
      case Scene.checking:
        break;
      case Scene.seeking:
        compass.sendLive(113, accuracy: CompassAccuracy.high);
      case Scene.aligned:
        compass.sendLive(cairoBearing, accuracy: CompassAccuracy.high);
      case Scene.calibrating:
        compass
          ..sendLive(80, accuracy: CompassAccuracy.high)
          ..send(80, accuracy: CompassAccuracy.low);
      case Scene.noSensor:
        await tester.pump(const Duration(seconds: 4));
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('states', () {
    testWidgets('checking: static dial, stats, no needle yet', (tester) async {
      await pumpQibla(tester);
      expect(find.byType(QiblaScreen), findsOneWidget);
      expect(find.text('Qibla'), findsWidgets);
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Finding north…'), findsOneWidget);
      expect(find.text('136°'), findsOneWidget);
      expect(find.text('from true North · SE'), findsOneWidget);
      expect(find.text('1,287 km'), findsOneWidget);
      expect(find.text('Great-circle'), findsOneWidget);
      final dial = tester.widget<QiblaDial>(find.byType(QiblaDial));
      expect(dial.heading, isNull);
    });

    testWidgets('seeking: turn amount, arc hint', (tester) async {
      await pumpQibla(tester);
      await show(tester, Scene.seeking);
      expect(find.text('Turn right 23°'), findsOneWidget);
      expect(
        find.text('Hold your phone flat. The gold arc shows how far to turn.'),
        findsOneWidget,
      );
      final dial = tester.widget<QiblaDial>(find.byType(QiblaDial));
      expect(dial.heading, closeTo(113, 0.1));
      expect(dial.aligned, isFalse);
      expect(
        find.bySemanticsLabel(
          'Qibla compass: the Qibla is 136° from north, you are facing 113°',
        ),
        findsOneWidget,
      );
    });

    testWidgets('seeking the other way says left', (tester) async {
      await pumpQibla(tester);
      compass.sendLive(170);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Turn left 34°'), findsOneWidget);
    });

    testWidgets('aligned: facing, gold needle state, vibration hint', (
      tester,
    ) async {
      await pumpQibla(tester);
      await show(tester, Scene.aligned);
      expect(find.text('Facing the Qibla'), findsOneWidget);
      expect(
        find.text('Hold your phone flat. It vibrates gently when aligned.'),
        findsOneWidget,
      );
      expect(tester.widget<QiblaDial>(find.byType(QiblaDial)).aligned, isTrue);
    });

    testWidgets('calibrating: figure-8 card over a dimmed dial', (
      tester,
    ) async {
      await pumpQibla(tester);
      await show(tester, Scene.calibrating);
      expect(find.text('Needs calibration'), findsOneWidget);
      expect(find.byType(CalibrationCard), findsOneWidget);
      expect(find.text('Calibrate your compass'), findsOneWidget);
      expect(find.text('Accuracy: low'), findsOneWidget);
      expect(tester.widget<QiblaDial>(find.byType(QiblaDial)).dimmed, isTrue);

      // Waving the phone fixes it.
      compass.send(81, accuracy: CompassAccuracy.medium);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CalibrationCard), findsNothing);
    });

    testWidgets('no sensor: bearing from north, gold line, Retry', (
      tester,
    ) async {
      await pumpQibla(tester);
      await show(tester, Scene.noSensor);
      expect(find.text('Static direction · no sensor'), findsOneWidget);
      expect(find.text('No compass sensor'), findsOneWidget);
      expect(
        find.text(
          'Your device can’t detect direction. Face North, then turn 136° '
          'clockwise — the Kaaba is along the gold line.',
        ),
        findsOneWidget,
      );
      expect(find.byType(QiblaStats), findsNothing);
      expect(tester.widget<QiblaDial>(find.byType(QiblaDial)).heading, isNull);
      expect(
        find.bySemanticsLabel('Qibla compass: the Qibla is 136° from north'),
        findsOneWidget,
      );

      expect(compass.starts, 1);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(compass.starts, 2);
      expect(find.text('Finding north…'), findsOneWidget);

      // A sensor that wakes up after Retry takes over.
      compass.sendLive(113);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Turn right 23°'), findsOneWidget);
    });

    testWidgets('no sensor on Android: constant readings', (tester) async {
      await pumpQibla(tester);
      for (var i = 0; i < 80; i++) {
        compass.send(0, accuracy: CompassAccuracy.high);
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(find.text('No compass sensor'), findsOneWidget);
      expect(tester.widget<QiblaDial>(find.byType(QiblaDial)).heading, isNull);
    });
  });

  group('haptics', () {
    testWidgets('one pulse per alignment, however much it jitters', (
      tester,
    ) async {
      await pumpQibla(tester);
      final pulses = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            pulses.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      compass.sendLive(100);
      for (var h = 100.0; h <= cairoBearing; h += 1) {
        compass.send(h);
        await tester.pump(const Duration(milliseconds: 32));
      }
      for (var i = 0; i < 60; i++) {
        compass.send(cairoBearing + (i.isEven ? 2 : -2));
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(pulses, ['HapticFeedbackType.mediumImpact']);

      // Away and back: a second pulse.
      for (var i = 0; i < 40; i++) {
        compass.send(cairoBearing + 40);
        await tester.pump(const Duration(milliseconds: 32));
      }
      for (var i = 0; i < 40; i++) {
        compass.send(cairoBearing);
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(pulses, hasLength(2));
    });
  });

  testWidgets('the sensor only runs while the tab is on screen', (
    tester,
  ) async {
    await pumpQibla(tester);
    expect(compass.isListening, isTrue);

    await tapNav(tester, 'Home');
    expect(compass.isListening, isFalse);

    await tapNav(tester, 'Qibla');
    expect(compass.isListening, isTrue);
  });

  testWidgets('follows a city picked in Settings', (tester) async {
    final location = FakeLocationService(lastKnown: cairo);
    await pumpQibla(tester, location: location);
    await location.useManualLocation(alexandria);
    await tester.pump();
    expect(find.text('Alexandria'), findsOneWidget);
    expect(find.text('Cairo'), findsNothing);
  });

  testWidgets('without a location, shows the same error as Home', (
    tester,
  ) async {
    final location = FakeLocationService(
      results: [const LocationFailed(LocationFailure.serviceDisabled)],
    );
    await pumpQibla(tester, location: location);
    expect(find.byType(LocationErrorView), findsOneWidget);
    expect(find.text('Can’t find your location'), findsOneWidget);

    await tester.tap(find.text('Location settings'));
    expect(location.locationSettingsOpened, 1);
  });

  group('Arabic', () {
    testWidgets('seeking reads right to left, Arabic-Indic digits', (
      tester,
    ) async {
      await pumpQibla(tester, lang: 'ar');
      await show(tester, Scene.seeking);
      expect(
        Directionality.of(tester.element(find.byType(QiblaDial))),
        TextDirection.rtl,
      );
      expect(find.text('استدر يمينًا ٢٣°'), findsOneWidget);
      expect(find.text('١٣٦°'), findsOneWidget);
      expect(find.text('من الشمال الحقيقي · جنوب شرق'), findsOneWidget);
      expect(find.text('١٬٢٨٧ كم'), findsOneWidget);
      expect(find.text('القاهرة'), findsOneWidget);
    });

    testWidgets('Western digits when chosen', (tester) async {
      compass = FakeCompassSensor();
      await pumpHayyaApp(
        tester,
        prefs: {'language_code': 'ar', 'numerals': 'western'},
        compass: compass,
      );
      await tapNav(tester, 'القبلة');
      expect(find.text('1,287 كم'), findsOneWidget);
    });
  });

  // Every state, every layout, both languages, both themes: nothing
  // overflows (the test fails on a RenderFlex overflow).
  group('no overflow', () {
    for (final (name, size) in [
      ('phone', phoneSize),
      ('small phone', const Size(320, 640)),
      ('tablet', tabletSize),
      ('tablet portrait', tabletPortrait),
    ]) {
      for (final lang in ['en', 'ar']) {
        for (final scene in Scene.values) {
          final theme = scene.index.isEven ? 'light' : 'dark';
          testWidgets('$name · $lang · $theme · ${scene.name}', (tester) async {
            await pumpQibla(tester, lang: lang, theme: theme, size: size);
            await show(tester, scene);
            expect(tester.takeException(), isNull);
            expect(find.byType(QiblaDial), findsOneWidget);

            // The dial is never wider than the screen.
            final dial = tester.getRect(find.byType(QiblaDial));
            expect(dial.left, greaterThanOrEqualTo(0));
            expect(dial.right, lessThanOrEqualTo(size.width));
          });
        }
      }
    }
  });
}

Future<void> tapNav(WidgetTester tester, String label) async {
  final nav = find.byWidgetPredicate(
    (w) => w is HayyaNavBar || w is HayyaNavRail,
  );
  await tester.tap(find.descendant(of: nav, matching: find.text(label)));
  await settle(tester, rounds: 2);
}
