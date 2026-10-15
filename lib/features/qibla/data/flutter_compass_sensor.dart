import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../domain/compass_sensor.dart';

/// [CompassSensor] on flutter_compass.
///
/// Without a magnetometer the plugin doesn't fail: Android keeps sending a
/// constant heading of 0 from the accelerometer alone, and iOS sends
/// nothing. [QiblaCubit] tells those apart from a working compass.
class FlutterCompassSensor implements CompassSensor {
  const FlutterCompassSensor();

  @override
  Stream<CompassReading> readings() {
    final events = FlutterCompass.events;
    if (events == null) return Stream.error(UnsupportedError('No compass'));
    final platform = defaultTargetPlatform;
    return events
        .map((event) => readingFrom(event, platform))
        .where((reading) => reading != null)
        .cast<CompassReading>();
  }

  /// The plugin's [event] on [platform]; null without a heading.
  ///
  /// The iOS plugin reports CoreLocation's `trueHeading`; Android's is the
  /// rotation-vector azimuth, from magnetic north.
  @visibleForTesting
  static CompassReading? readingFrom(
    CompassEvent event,
    TargetPlatform platform,
  ) {
    final heading = event.heading;
    if (heading == null || !heading.isFinite) return null;
    return CompassReading(
      heading: heading,
      north: platform == TargetPlatform.iOS
          ? NorthReference.trueNorth
          : NorthReference.magnetic,
      accuracy: switch (event.accuracy) {
        final error? when error >= 0 => CompassAccuracy.fromErrorDegrees(error),
        _ => null,
      },
    );
  }
}
