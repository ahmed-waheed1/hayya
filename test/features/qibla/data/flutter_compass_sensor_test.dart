import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/qibla/data/flutter_compass_sensor.dart';
import 'package:hayya/features/qibla/domain/compass_sensor.dart';

void main() {
  CompassReading? read(List<double>? data, TargetPlatform platform) =>
      FlutterCompassSensor.readingFrom(CompassEvent.fromList(data), platform);

  test('iOS headings are true north (the plugin sends trueHeading)', () {
    expect(
      read([136, 136, 10], TargetPlatform.iOS),
      const CompassReading(
        heading: 136,
        north: NorthReference.trueNorth,
        accuracy: CompassAccuracy.high,
      ),
    );
  });

  test('Android headings are magnetic', () {
    expect(
      read([-90, 0, 45], TargetPlatform.android)?.north,
      NorthReference.magnetic,
    );
  });

  test('accuracy maps from the plugin\'s ± degrees; −1 is unknown', () {
    expect(
      read([0, 0, 15], TargetPlatform.android)?.accuracy,
      CompassAccuracy.high,
    );
    expect(
      read([0, 0, 30], TargetPlatform.android)?.accuracy,
      CompassAccuracy.medium,
    );
    expect(
      read([0, 0, 45], TargetPlatform.android)?.accuracy,
      CompassAccuracy.low,
    );
    expect(read([0, 0, -1], TargetPlatform.android)?.accuracy, isNull);
  });

  test('events without a heading are dropped', () {
    expect(read(null, TargetPlatform.android), isNull);
    expect(read([double.nan, 0, 15], TargetPlatform.iOS), isNull);
  });
}
