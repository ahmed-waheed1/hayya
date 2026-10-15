import 'dart:async';

import 'package:hayya/features/qibla/domain/compass_sensor.dart';

/// [CompassSensor] driven by the test: [send] readings, [fail] the stream.
/// Silent until told otherwise, like a device without a compass on iOS.
///
/// Headings are from [north]: true north by default, so tests can reason
/// about the dial without the declination; pass [NorthReference.magnetic]
/// to act like Android.
class FakeCompassSensor implements CompassSensor {
  FakeCompassSensor({this.north = NorthReference.trueNorth});

  final NorthReference north;

  final _controller = StreamController<CompassReading>.broadcast(sync: true);

  /// How many times the sensor was started.
  var starts = 0;

  bool get isListening => _controller.hasListener;

  @override
  Stream<CompassReading> readings() {
    starts++;
    return _controller.stream;
  }

  void send(double heading, {CompassAccuracy? accuracy}) => _controller.add(
    CompassReading(heading: heading, north: north, accuracy: accuracy),
  );

  /// A working sensor jitters: sends [heading] and a hair off it, so the
  /// readings are never all identical.
  void sendLive(double heading, {CompassAccuracy? accuracy}) {
    send(heading + 0.01, accuracy: accuracy);
    send(heading, accuracy: accuracy);
  }

  void fail() => _controller.addError(StateError('sensor failed'));
}
