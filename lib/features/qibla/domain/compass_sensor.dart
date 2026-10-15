import 'package:equatable/equatable.dart';

/// How far the sensor's heading can be off.
enum CompassAccuracy {
  high,
  medium,
  low;

  /// From the platform's ± error in degrees. Android only reports three
  /// fixed values (15, 30, 45); iOS reports a measured error.
  static CompassAccuracy fromErrorDegrees(double degrees) => switch (degrees) {
    <= 20 => high,
    <= 35 => medium,
    _ => low,
  };
}

/// Which north a heading is measured from.
enum NorthReference {
  /// Magnetic north (Android): needs the magnetic declination added.
  magnetic,

  /// True north (iOS corrects it already): use as is.
  trueNorth,
}

/// One compass sample.
class CompassReading extends Equatable {
  const CompassReading({
    required this.heading,
    required this.north,
    this.accuracy,
  });

  /// Where the top of the device points, in degrees clockwise from [north].
  final double heading;

  /// Required, so no source can leave it to a default: correcting a true
  /// heading again would be off by the declination.
  final NorthReference north;

  /// Null when the platform doesn't say.
  final CompassAccuracy? accuracy;

  @override
  List<Object?> get props => [heading, north, accuracy];
}

/// The device's compass.
abstract interface class CompassSensor {
  /// Starts the sensor; it stops when the subscription is cancelled.
  ///
  /// May never emit, or emit an error, on a device without a compass.
  Stream<CompassReading> readings();
}
