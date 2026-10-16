import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../domain/entities/prayer_calculation_settings.dart';
import '../../domain/repositories/hijri_calendar_repository.dart';
import '../../domain/repositories/prayer_settings_repository.dart';
import '../../domain/usecases/get_hijri_date.dart';
import '../../domain/usecases/get_prayer_schedule.dart';
import 'prayer_times_state.dart';

/// Drives Home: finds the location, then ticks the schedule every second.
///
/// A cached location is shown straight away and refreshed in the
/// background; a failed background refresh keeps the cached times.
/// Only a refresh the user asked for replaces them with an error.
///
/// A location chosen elsewhere (a city picked in Settings) and changes to
/// the calculation settings or the Hijri adjustment apply straight away.
///
/// The location permission is asked for in onboarding, so opening Home
/// never prompts; without a location it shows the error view, whose
/// "Allow location" does.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({
    required this._locationService,
    required this._settingsRepository,
    required this._getSchedule,
    required this._getHijriDate,
    required this._hijriCalendar,
    this._clock = DateTime.now,
  }) : super(const PrayerTimesLoading());

  final LocationService _locationService;
  final PrayerSettingsRepository _settingsRepository;
  final GetPrayerSchedule _getSchedule;
  final GetHijriDate _getHijriDate;
  final HijriCalendarRepository _hijriCalendar;
  final DateTime Function() _clock;

  Timer? _ticker;
  final _subscriptions = <StreamSubscription<Object?>>[];
  late PrayerCalculationSettings _settings;
  UserLocation? _location;
  bool _locating = false;

  Future<void> start() async {
    _settings = _settingsRepository.settings;
    _subscriptions.addAll([
      _settingsRepository.changes.listen((settings) {
        _settings = settings;
        if (_location != null) _emitSchedule();
      }),
      _hijriCalendar.adjustmentChanges.listen((_) {
        if (_location != null) _emitSchedule();
      }),
      _locationService.changes.listen(_show),
    ]);

    final cached = _locationService.lastKnown;
    if (cached != null) _show(cached);
    await _locate(userAsked: cached == null, requestPermission: false);
  }

  /// The user asked for a fresh location (city chip, Try again, Allow).
  Future<void> refresh() => _locate(userAsked: true);

  /// Back from the system settings: check again without prompting, so a
  /// declined permission dialog can't reopen itself on every resume.
  Future<void> recheck() async {
    if (state is PrayerTimesLocationError) {
      await _locate(userAsked: true, requestPermission: false);
    }
  }

  /// Leaves an error screen for the cached location's times.
  void useLastKnown() {
    final current = state;
    if (current is PrayerTimesLocationError && current.lastKnown != null) {
      _show(current.lastKnown!);
    }
  }

  Future<void> openSettingsFor(LocationFailure reason) =>
      reason == LocationFailure.serviceDisabled
      ? _locationService.openLocationSettings()
      : _locationService.openAppSettings();

  Future<void> _locate({
    required bool userAsked,
    bool? requestPermission,
  }) async {
    if (_locating) return;
    _locating = true;
    if (_location != null) {
      _emitSchedule();
    } else {
      emit(const PrayerTimesLoading());
    }

    final result = await _locationService.locate(
      requestPermission: requestPermission ?? userAsked,
    );
    _locating = false;
    if (isClosed) return;

    switch (result) {
      case LocationFound(:final location):
        _show(location);
      case LocationFailed(:final reason) when userAsked || _location == null:
        _stopTicker();
        _location = null;
        emit(
          PrayerTimesLocationError(
            reason,
            lastKnown: _locationService.lastKnown,
          ),
        );
      case LocationFailed():
        _emitSchedule();
    }
  }

  void _show(UserLocation location) {
    _location = location;
    _emitSchedule();
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _emitSchedule(),
    );
  }

  void _emitSchedule() {
    final location = _location!;
    final schedule = _getSchedule(
      now: _clock(),
      coordinates: location.coordinates,
      settings: _settings,
    );
    emit(
      PrayerTimesReady(
        location: location,
        schedule: schedule,
        hijriDate: _getHijriDate(schedule.today.date),
        locating: _locating,
      ),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() async {
    _stopTicker();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}
