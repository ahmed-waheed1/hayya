import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../domain/compass_sensor.dart';
import '../../domain/heading_math.dart';
import '../../domain/magnetic_declination.dart';
import '../../domain/qibla_alignment.dart';
import '../../domain/qibla_direction.dart';
import 'qibla_state.dart';

/// Drives the Qibla screen: the bearing and distance from the same
/// location Home uses (a device fix or a city picked in Settings), and the
/// phone's heading from the compass.
///
/// A device without a working compass is detected two ways, because the
/// plugin doesn't report it: no readings at all within [silenceTimeout]
/// (iOS), or readings that never change for [frozenAfter] (Android sends a
/// constant 0 when there is no magnetometer; a real sensor always
/// jitters). Either way the screen falls back to the static bearing, and
/// recovers by itself if live readings start arriving.
///
/// Magnetic headings (Android) are turned into true ones with the
/// declination at the location (World Magnetic Model), since the Qibla
/// bearing is from true north. True headings (iOS) are used as they are.
class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({
    required this._locationService,
    required this._compass,
    this.silenceTimeout = const Duration(seconds: 3),
    this.frozenAfter = const Duration(seconds: 2),
    this._clock = DateTime.now,
  }) : super(const QiblaLoading());

  final LocationService _locationService;
  final CompassSensor _compass;
  final Duration silenceTimeout;
  final Duration frozenAfter;
  final DateTime Function() _clock;

  StreamSubscription<UserLocation>? _locationChanges;
  UserLocation? _location;
  bool _locating = false;

  /// Magnetic declination at [_location]; 0 until a location is known.
  double _declination = 0;

  StreamSubscription<CompassReading>? _readings;
  Timer? _silenceTimer;
  Timer? _frozenTimer;
  final _smoother = HeadingSmoother();
  final _alignment = AlignmentTracker();
  CompassStatus _status = CompassStatus.checking;
  CompassAccuracy? _accuracy;

  /// The first heading seen, and whether any later one differed from it.
  double? _firstHeading;
  bool _varied = false;

  Future<void> start() async {
    _locationChanges = _locationService.changes.listen(_show);
    _startCompass();
    final cached = _locationService.lastKnown;
    if (cached != null) {
      _show(cached);
    } else {
      // Onboarding asks for the permission; the error view's Allow
      // button asks again.
      await _locate(requestPermission: false);
    }
  }

  /// The user asked for a fresh location (Try again, Allow).
  Future<void> refresh() => _locate(requestPermission: true);

  /// Back from the system settings: check again without prompting.
  Future<void> recheck() async {
    if (state is QiblaLocationError) await _locate(requestPermission: false);
  }

  void useLastKnown() {
    final current = state;
    if (current is QiblaLocationError && current.lastKnown != null) {
      _show(current.lastKnown!);
    }
  }

  Future<void> openSettingsFor(LocationFailure reason) =>
      reason == LocationFailure.serviceDisabled
      ? _locationService.openLocationSettings()
      : _locationService.openAppSettings();

  /// Runs the sensor only while the screen is visible. What was learned
  /// about it (whether it works) is kept across pauses.
  void setCompassActive(bool active) {
    if (active) {
      if (_readings == null) _startCompass();
    } else {
      _stopCompass();
    }
  }

  /// Starts the compass check over (the no-sensor "Retry").
  void retryCompass() {
    _stopCompass();
    _varied = false;
    _accuracy = null;
    _smoother.reset();
    _alignment.reset();
    _status = CompassStatus.checking;
    _emitReady();
    _startCompass();
  }

  Future<void> _locate({required bool requestPermission}) async {
    if (_locating) return;
    _locating = true;
    if (_location == null) emit(const QiblaLoading());
    final result = await _locationService.locate(
      requestPermission: requestPermission,
    );
    _locating = false;
    if (isClosed) return;
    switch (result) {
      case LocationFound(:final location):
        _show(location);
      case LocationFailed(:final reason):
        _location = null;
        emit(QiblaLocationError(reason, lastKnown: _locationService.lastKnown));
    }
  }

  void _show(UserLocation location) {
    if (isClosed) return;
    _location = location;
    _declination = magneticDeclination(location.coordinates, _clock());
    _emitReady();
  }

  void _startCompass() {
    final Stream<CompassReading> readings;
    try {
      readings = _compass.readings();
    } catch (_) {
      _setStatus(CompassStatus.noSensor);
      return;
    }
    _readings = readings.listen(
      _onReading,
      onError: (Object _) => _onSensorFailed(),
      onDone: () => _readings = null,
    );
    if (!_varied) {
      // Not proven yet: check from scratch (a pause cancelled the timers).
      _firstHeading = null;
      _silenceTimer = Timer(silenceTimeout, () {
        if (_firstHeading == null) _setStatus(CompassStatus.noSensor);
      });
    }
  }

  void _stopCompass() {
    _readings?.cancel();
    _readings = null;
    _silenceTimer?.cancel();
    _frozenTimer?.cancel();
  }

  void _onSensorFailed() {
    _stopCompass();
    _setStatus(CompassStatus.noSensor);
  }

  void _onReading(CompassReading reading) {
    // The sensor's own value, for the frozen check below: the correction
    // changes with the location, which isn't the sensor moving.
    final heading = normalizeDegrees(reading.heading);
    _accuracy = reading.accuracy;
    _smoother.add(switch (reading.north) {
      NorthReference.magnetic => heading + _declination,
      NorthReference.trueNorth => heading,
    });

    if (!_varied) {
      final first = _firstHeading;
      if (first == null) {
        _firstHeading = heading;
        _silenceTimer?.cancel();
        _frozenTimer = Timer(frozenAfter, () {
          if (!_varied) _setStatus(CompassStatus.noSensor);
        });
      } else if (heading != first) {
        _varied = true;
        _frozenTimer?.cancel();
      }
    }

    if (_varied) {
      _status = _accuracy == CompassAccuracy.low
          ? CompassStatus.calibrating
          : CompassStatus.live;
    }
    _emitReady();
  }

  void _setStatus(CompassStatus status) {
    if (isClosed) return;
    _status = status;
    _emitReady();
  }

  void _emitReady() {
    final location = _location;
    if (location == null || isClosed) return;
    final bearing = qiblaBearing(location.coordinates);
    final heading = _status == CompassStatus.noSensor ? null : _smoother.value;

    var aligned = false;
    if (_status == CompassStatus.live && heading != null) {
      aligned = _alignment.update(heading: heading, bearing: bearing);
    } else {
      _alignment.reset();
    }

    emit(
      QiblaReady(
        location: location,
        bearing: bearing,
        distanceKm: distanceToKaabaKm(location.coordinates),
        compass: _status,
        heading: _status == CompassStatus.checking ? null : heading,
        accuracy: _accuracy,
        aligned: aligned,
      ),
    );
  }

  @override
  Future<void> close() async {
    _stopCompass();
    await _locationChanges?.cancel();
    return super.close();
  }
}
