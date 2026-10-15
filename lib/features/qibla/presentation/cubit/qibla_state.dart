import 'package:equatable/equatable.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../domain/compass_sensor.dart';
import '../../domain/heading_math.dart';

enum CompassStatus {
  /// Waiting for the first readings that prove the compass works.
  checking,

  /// Working; the dial follows the phone.
  live,

  /// Working but inaccurate; the user should wave the phone in a figure 8.
  calibrating,

  /// No usable compass: the dial shows the bearing from north instead.
  noSensor,
}

sealed class QiblaState extends Equatable {
  const QiblaState();

  @override
  List<Object?> get props => [];
}

/// No location known yet.
final class QiblaLoading extends QiblaState {
  const QiblaLoading();
}

/// No usable location. [lastKnown], when present, can be used instead.
final class QiblaLocationError extends QiblaState {
  const QiblaLocationError(this.reason, {this.lastKnown});

  final LocationFailure reason;
  final UserLocation? lastKnown;

  @override
  List<Object?> get props => [reason, lastKnown];
}

final class QiblaReady extends QiblaState {
  const QiblaReady({
    required this.location,
    required this.bearing,
    required this.distanceKm,
    required this.compass,
    this.heading,
    this.accuracy,
    this.aligned = false,
  });

  final UserLocation location;

  /// Qibla direction, degrees clockwise from true north (0–360).
  final double bearing;

  /// Great-circle distance to the Kaaba.
  final double distanceKm;

  final CompassStatus compass;

  /// The phone's smoothed heading, unwrapped (it can pass 360 or go below
  /// 0, so the dial always turns the short way). Null until the compass
  /// has been read.
  final double? heading;

  final CompassAccuracy? accuracy;

  /// Facing the Qibla (only while [compass] is [CompassStatus.live]).
  final bool aligned;

  /// How far to turn to face the Qibla: positive clockwise (right),
  /// negative counter-clockwise (left). Null without a heading.
  double? get turn => heading == null ? null : shortestTurn(heading!, bearing);

  @override
  List<Object?> get props => [
    location,
    bearing,
    distanceKm,
    compass,
    heading,
    accuracy,
    aligned,
  ];
}
