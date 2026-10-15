import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/qibla/domain/compass_sensor.dart';
import 'package:hayya/features/qibla/domain/heading_math.dart';
import 'package:hayya/features/qibla/domain/qibla_direction.dart';
import 'package:hayya/features/qibla/presentation/cubit/qibla_cubit.dart';
import 'package:hayya/features/qibla/presentation/cubit/qibla_state.dart';

import '../../../helpers/fake_compass_sensor.dart';
import '../../../helpers/fake_location_service.dart';

/// Run as widget tests for the fake clock: `tester.pump(duration)` fires the
/// cubit's timers.
void main() {
  late FakeCompassSensor compass;
  late FakeLocationService location;
  final cubits = <QiblaCubit>[];

  /// [testWidgets] that closes the test's cubits before it checks for
  /// pending timers (tear-downs run too late for that).
  void qiblaTest(String description, WidgetTesterCallback body) =>
      testWidgets(description, (tester) async {
        cubits.clear();
        await body(tester);
        for (final cubit in cubits) {
          unawaited(cubit.close());
        }
        await tester.pump();
      });

  Future<QiblaCubit> startCubit({
    FakeLocationService? with_,
    NorthReference north = NorthReference.trueNorth,
  }) async {
    compass = FakeCompassSensor(north: north);
    location = with_ ?? FakeLocationService(lastKnown: cairo);
    final cubit = QiblaCubit(
      locationService: location,
      compass: compass,
      clock: () => DateTime(2026, 10, 15),
    );
    cubits.add(cubit);
    await cubit.start();
    return cubit;
  }

  QiblaReady ready(QiblaCubit cubit) => cubit.state as QiblaReady;

  group('location', () {
    qiblaTest('uses Home\'s location straight away', (tester) async {
      final cubit = await startCubit();
      final state = ready(cubit);
      expect(state.location, cairo);
      expect(state.bearing, closeTo(136.14, 0.01));
      expect(state.distanceKm, closeTo(1287.2, 0.1));
      expect(state.compass, CompassStatus.checking);
      expect(state.heading, isNull);
    });

    qiblaTest('follows a city picked in Settings', (tester) async {
      final cubit = await startCubit();
      await location.useManualLocation(alexandria);
      expect(ready(cubit).location, alexandria);
      expect(ready(cubit).bearing, qiblaBearing(alexandria.coordinates));
    });

    qiblaTest('locates when nothing is cached', (tester) async {
      final cubit = await startCubit(with_: FakeLocationService());
      expect(ready(cubit).location, cairo);
      expect(location.permissionRequests, [true]);
    });

    qiblaTest('shows why the location failed, and can fall back', (
      tester,
    ) async {
      final fake = FakeLocationService(
        results: [const LocationFailed(LocationFailure.permissionDenied)],
      );
      final cubit = await startCubit(with_: fake);
      expect(
        cubit.state,
        const QiblaLocationError(LocationFailure.permissionDenied),
      );

      fake.lastKnown = alexandria;
      await cubit.recheck();
      expect(location.permissionRequests, [true, false]);
      expect(cubit.state, isA<QiblaLocationError>());
      cubit.useLastKnown();
      expect(ready(cubit).location, alexandria);
    });
  });

  group('no compass', () {
    qiblaTest('silent sensor (iOS): falls back after 3 s', (tester) async {
      final cubit = await startCubit();
      await tester.pump(const Duration(milliseconds: 2900));
      expect(ready(cubit).compass, CompassStatus.checking);
      await tester.pump(const Duration(milliseconds: 200));
      expect(ready(cubit).compass, CompassStatus.noSensor);
      expect(ready(cubit).heading, isNull);
      expect(ready(cubit).aligned, isFalse);
      // The bearing is still there for the static dial.
      expect(ready(cubit).bearing, closeTo(136.14, 0.01));
    });

    qiblaTest('constant heading (Android, no magnetometer): falls back '
        'even though readings keep coming', (tester) async {
      final cubit = await startCubit();
      for (var i = 0; i < 80; i++) {
        compass.send(0, accuracy: CompassAccuracy.high);
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(ready(cubit).compass, CompassStatus.noSensor);
      expect(ready(cubit).heading, isNull);
    });

    qiblaTest('a constant heading never shows a needle meanwhile', (
      tester,
    ) async {
      final cubit = await startCubit();
      final seen = <CompassStatus>{};
      for (var i = 0; i < 80; i++) {
        compass.send(0);
        seen.add(ready(cubit).compass);
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(seen, {CompassStatus.checking, CompassStatus.noSensor});
    });

    qiblaTest('a sensor error falls back at once', (tester) async {
      final cubit = await startCubit();
      compass.fail();
      expect(ready(cubit).compass, CompassStatus.noSensor);
      expect(compass.isListening, isFalse);
    });

    qiblaTest('recovers by itself when live readings start', (tester) async {
      final cubit = await startCubit();
      await tester.pump(const Duration(seconds: 4));
      expect(ready(cubit).compass, CompassStatus.noSensor);

      compass.sendLive(90);
      expect(ready(cubit).compass, CompassStatus.live);
      expect(ready(cubit).heading, isNotNull);
    });

    qiblaTest('Retry checks again from scratch', (tester) async {
      final cubit = await startCubit();
      await tester.pump(const Duration(seconds: 4));
      expect(ready(cubit).compass, CompassStatus.noSensor);

      cubit.retryCompass();
      expect(ready(cubit).compass, CompassStatus.checking);
      expect(compass.starts, 2);
      expect(compass.isListening, isTrue);
      await tester.pump(const Duration(seconds: 4));
      expect(ready(cubit).compass, CompassStatus.noSensor);
    });
  });

  group('live compass', () {
    qiblaTest('goes live as soon as readings vary', (tester) async {
      final cubit = await startCubit();
      compass.send(113);
      expect(ready(cubit).compass, CompassStatus.checking);
      compass.send(113.2);
      expect(ready(cubit).compass, CompassStatus.live);
      expect(normalizeDegrees(ready(cubit).heading!), closeTo(113, 0.2));
      expect(ready(cubit).turn, closeTo(23, 0.3));

      // Proven: a still phone later doesn't trip the frozen check.
      for (var i = 0; i < 100; i++) {
        compass.send(113.2);
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(ready(cubit).compass, CompassStatus.live);
    });

    qiblaTest('accepts Android\'s −180…180 headings', (tester) async {
      final cubit = await startCubit();
      for (var i = 0; i < 30; i++) {
        compass.send(i.isEven ? -90 : -90.1);
      }
      expect(normalizeDegrees(ready(cubit).heading!), closeTo(270, 0.2));
    });

    qiblaTest('smooths and turns the short way across north', (tester) async {
      final cubit = await startCubit();
      compass.sendLive(358);
      final headings = <double>[];
      for (var i = 0; i < 30; i++) {
        compass.send(i.isEven ? 4 : 4.01);
        headings.add(ready(cubit).heading!);
      }
      // Up through 360 toward 364 (= 4°), never back round through 180.
      expect(headings.every((h) => h > 357.9 && h < 364.02), isTrue);
      expect(headings.last, closeTo(364, 0.1));
    });

    qiblaTest('aligns once within a few degrees, and lets go past 5°', (
      tester,
    ) async {
      final cubit = await startCubit();
      final bearing = ready(cubit).bearing;
      final alignedChanges = <bool>[];
      cubit.stream.listen((s) {
        if (s is QiblaReady &&
            (alignedChanges.isEmpty || alignedChanges.last != s.aligned)) {
          alignedChanges.add(s.aligned);
        }
      });

      // Turn from 113° to the Qibla, with jitter, and hold.
      for (var h = 113.0; h <= bearing; h += 0.5) {
        compass.sendLive(h);
      }
      for (var i = 0; i < 60; i++) {
        compass.send(bearing + (i.isEven ? 1.5 : -1.5));
      }
      await tester.pump();
      expect(ready(cubit).aligned, isTrue);

      // Turn away.
      for (var i = 0; i < 60; i++) {
        compass.send(bearing + 30);
      }
      await tester.pump();
      expect(ready(cubit).aligned, isFalse);
      expect(alignedChanges, [false, true, false]);
    });

    qiblaTest('low accuracy asks for calibration until it improves', (
      tester,
    ) async {
      final cubit = await startCubit();
      compass.sendLive(136, accuracy: CompassAccuracy.high);
      expect(ready(cubit).aligned, isTrue);

      compass.send(136.1, accuracy: CompassAccuracy.low);
      expect(ready(cubit).compass, CompassStatus.calibrating);
      expect(ready(cubit).accuracy, CompassAccuracy.low);
      expect(ready(cubit).aligned, isFalse, reason: 'no alignment while off');
      expect(ready(cubit).heading, isNotNull, reason: 'the dial keeps turning');

      compass.send(136, accuracy: CompassAccuracy.medium);
      expect(ready(cubit).compass, CompassStatus.live);
      expect(ready(cubit).aligned, isTrue);
    });

    qiblaTest('unknown accuracy is not treated as low', (tester) async {
      final cubit = await startCubit();
      compass.sendLive(10);
      expect(ready(cubit).compass, CompassStatus.live);
    });
  });

  group('true north', () {
    // WMM2025 on 2026-10-15 (see magnetic_declination_test.dart).
    const cairoDeclination = 4.77114;
    const newYorkDeclination = -12.46302;

    qiblaTest('Android: a magnetic heading gets the declination added', (
      tester,
    ) async {
      final cubit = await startCubit(north: NorthReference.magnetic);
      final bearing = ready(cubit).bearing;

      // Facing the Qibla means the magnetic compass reads 4.77° less.
      compass.sendLive(bearing - cairoDeclination);
      expect(normalizeDegrees(ready(cubit).heading!), closeTo(bearing, 0.01));
      expect(ready(cubit).aligned, isTrue);
    });

    qiblaTest('iOS: a true heading is not corrected a second time', (
      tester,
    ) async {
      final cubit = await startCubit(north: NorthReference.trueNorth);
      final bearing = ready(cubit).bearing;

      compass.sendLive(bearing);
      expect(normalizeDegrees(ready(cubit).heading!), closeTo(bearing, 0.01));
      expect(ready(cubit).aligned, isTrue);
    });

    qiblaTest('iOS: the magnetic reading would be 4.77° off, not aligned', (
      tester,
    ) async {
      final cubit = await startCubit(north: NorthReference.trueNorth);
      compass.sendLive(ready(cubit).bearing - cairoDeclination);
      expect(ready(cubit).aligned, isFalse);
      expect(ready(cubit).turn, closeTo(cairoDeclination, 0.01));
    });

    qiblaTest('the correction follows the location (west in New York)', (
      tester,
    ) async {
      final newYork = UserLocation(
        coordinates: const GeoCoordinates(40.7128, -74.0060),
        updatedAt: DateTime(2026, 10, 15),
      );
      final cubit = await startCubit(north: NorthReference.magnetic);
      await location.useManualLocation(newYork);
      final bearing = ready(cubit).bearing;
      expect(bearing, closeTo(58.48, 0.01));

      // Magnetic north is 12.46° west, so the compass reads 12.46° more.
      for (var i = 0; i < 40; i++) {
        compass.send(bearing - newYorkDeclination + (i.isEven ? 0.01 : 0));
      }
      expect(normalizeDegrees(ready(cubit).heading!), closeTo(bearing, 0.02));
      expect(ready(cubit).aligned, isTrue);
    });

    qiblaTest('a location change during the check is not mistaken for '
        'a live sensor', (tester) async {
      final cubit = await startCubit(north: NorthReference.magnetic);
      compass.send(0);
      await location.useManualLocation(alexandria);
      for (var i = 0; i < 80; i++) {
        compass.send(0);
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(ready(cubit).compass, CompassStatus.noSensor);
    });
  });

  group('pausing', () {
    qiblaTest('stops the sensor while hidden, and resumes live', (
      tester,
    ) async {
      final cubit = await startCubit();
      compass.sendLive(50);
      expect(compass.isListening, isTrue);

      cubit.setCompassActive(false);
      expect(compass.isListening, isFalse);
      await tester.pump(const Duration(seconds: 10));
      expect(ready(cubit).compass, CompassStatus.live, reason: 'no timeout');

      cubit.setCompassActive(true);
      expect(compass.isListening, isTrue);
      expect(compass.starts, 2);
      await tester.pump(const Duration(seconds: 10));
      expect(ready(cubit).compass, CompassStatus.live, reason: 'still proven');
    });

    qiblaTest('a pause mid-check restarts the check', (tester) async {
      final cubit = await startCubit();
      compass.send(0);
      cubit.setCompassActive(false);
      await tester.pump(const Duration(seconds: 10));
      expect(ready(cubit).compass, CompassStatus.checking);

      cubit.setCompassActive(true);
      for (var i = 0; i < 80; i++) {
        compass.send(0);
        await tester.pump(const Duration(milliseconds: 32));
      }
      expect(ready(cubit).compass, CompassStatus.noSensor);
    });

    qiblaTest('closing stops the sensor', (tester) async {
      final cubit = await startCubit();
      unawaited(cubit.close());
      expect(compass.isListening, isFalse);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
