import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/repositories/hijri_calendar_repository.dart';
import '../../../prayer_times/domain/repositories/prayer_settings_repository.dart';
import '../../domain/entities/timetable_month.dart';
import '../../domain/usecases/get_month_timetable.dart';
import 'timetable_state.dart';

/// Drives the monthly timetable. Opens on the current month.
///
/// Uses the location Home shows (the cached fix or the city picked in
/// Settings) without looking it up again, and recalculates when the
/// location, the calculation settings or the Hijri adjustment change.
class TimetableCubit extends Cubit<TimetableState> {
  TimetableCubit({
    required this._locationService,
    required this._settingsRepository,
    required this._hijriCalendar,
    required this._getTimetable,
    this._clock = DateTime.now,
  }) : super(const TimetableNoLocation());

  final LocationService _locationService;
  final PrayerSettingsRepository _settingsRepository;
  final HijriCalendarRepository _hijriCalendar;
  final GetMonthTimetable _getTimetable;
  final DateTime Function() _clock;

  final _subscriptions = <StreamSubscription<Object?>>[];
  late PrayerCalculationSettings _settings;
  late CalendarMonth _month;
  UserLocation? _location;

  void start() {
    _settings = _settingsRepository.settings;
    _location = _locationService.lastKnown;
    _month = CalendarMonth.of(_clock());
    _subscriptions.addAll([
      _settingsRepository.changes.listen((settings) {
        _settings = settings;
        _emit();
      }),
      _hijriCalendar.adjustmentChanges.listen((_) => _emit()),
      _locationService.changes.listen((location) {
        _location = location;
        _emit();
      }),
    ]);
    _emit();
  }

  void showNextMonth() => _show(_month.next);

  void showPreviousMonth() => _show(_month.previous);

  void showCurrentMonth() => _show(CalendarMonth.of(_clock()));

  /// Moves the highlight when the day has changed (back from the
  /// background after midnight).
  void refreshToday() {
    final current = state;
    if (current is TimetableReady && current.today != _today()) _emit();
  }

  void _show(CalendarMonth month) {
    _month = month;
    _emit();
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  void _emit() {
    if (isClosed) return;
    final location = _location;
    if (location == null) {
      emit(const TimetableNoLocation());
      return;
    }
    emit(
      TimetableReady(
        location: location,
        settings: _settings,
        timetable: _getTimetable(
          _month,
          coordinates: location.coordinates,
          settings: _settings,
        ),
        today: _today(),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}
