import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../../prayer_times/domain/entities/hijri_date.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/repositories/hijri_calendar_repository.dart';
import '../../../prayer_times/domain/repositories/prayer_settings_repository.dart';
import '../../../prayer_times/domain/usecases/suggest_calculation_method.dart';

class PrayerSettingsState extends Equatable {
  const PrayerSettingsState({
    required this.settings,
    required this.hijriAdjustmentDays,
    required this.hijriToday,
    this.location,
  });

  final PrayerCalculationSettings settings;
  final int hijriAdjustmentDays;

  /// Today's Hijri date with [hijriAdjustmentDays] applied, as a preview.
  final HijriDate hijriToday;

  /// Where times are calculated for; null before the first fix.
  final UserLocation? location;

  /// The usual method in the location's country, if it is known.
  CalculationMethod? get suggestedMethod =>
      suggestCalculationMethod(location?.countryCode);

  /// The rule only matters far from the equator. It stays visible once
  /// changed, so it can always be changed back.
  bool get showsHighLatitudeRule {
    final latitude = location?.coordinates.latitude;
    return settings.highLatitudeRule !=
            const PrayerCalculationSettings().highLatitudeRule ||
        (latitude != null &&
            latitude.abs() >= HighLatitudeRule.relevantFromLatitude);
  }

  PrayerSettingsState copyWith({
    PrayerCalculationSettings? settings,
    int? hijriAdjustmentDays,
    HijriDate? hijriToday,
    UserLocation? location,
  }) => PrayerSettingsState(
    settings: settings ?? this.settings,
    hijriAdjustmentDays: hijriAdjustmentDays ?? this.hijriAdjustmentDays,
    hijriToday: hijriToday ?? this.hijriToday,
    location: location ?? this.location,
  );

  @override
  List<Object?> get props => [
    settings,
    hijriAdjustmentDays,
    hijriToday,
    location,
  ];
}

/// Settings → Prayer times, Manual adjustments and the Hijri date.
///
/// Saving through the repositories is enough: Home and the adhan schedule
/// listen to them.
class PrayerSettingsCubit extends Cubit<PrayerSettingsState> {
  PrayerSettingsCubit({
    required this._settingsRepository,
    required this._hijriCalendar,
    required LocationService locationService,
    this._clock = DateTime.now,
  }) : super(
         PrayerSettingsState(
           settings: _settingsRepository.settings,
           hijriAdjustmentDays: _hijriCalendar.adjustmentDays,
           hijriToday: _hijriCalendar.fromGregorian(_clock()),
           location: locationService.lastKnown,
         ),
       ) {
    _locations = locationService.changes.listen(
      (location) => emit(state.copyWith(location: location)),
    );
  }

  final PrayerSettingsRepository _settingsRepository;
  final HijriCalendarRepository _hijriCalendar;
  final DateTime Function() _clock;
  late final StreamSubscription<UserLocation> _locations;

  Future<void> setMethod(CalculationMethod method) =>
      _save(state.settings.copyWith(method: method));

  Future<void> setMadhab(AsrMadhab madhab) =>
      _save(state.settings.copyWith(madhab: madhab));

  Future<void> setHighLatitudeRule(HighLatitudeRule rule) =>
      _save(state.settings.copyWith(highLatitudeRule: rule));

  /// Moves [prayer] by [minutes] (±1 from the steppers), within ±30.
  Future<void> adjust(Prayer prayer, int minutes) {
    final next = state.settings.withAdjustment(
      prayer,
      state.settings.adjustmentFor(prayer) + minutes,
    );
    return next == state.settings ? Future.value() : _save(next);
  }

  /// Moves the Hijri date by [days] (±1 from the stepper), within ±2.
  Future<void> adjustHijri(int days) async {
    // From the repository, not the state, so taps made while a save is
    // still running add up.
    final current = _hijriCalendar.adjustmentDays;
    final next = (current + days).clamp(-maxAdjustmentDays, maxAdjustmentDays);
    if (next == current) return;
    await _hijriCalendar.saveAdjustmentDays(next);
    if (isClosed) return;
    emit(
      state.copyWith(
        hijriAdjustmentDays: next,
        hijriToday: _hijriCalendar.fromGregorian(_clock()),
      ),
    );
  }

  Future<void> _save(PrayerCalculationSettings settings) async {
    emit(state.copyWith(settings: settings));
    await _settingsRepository.save(settings);
  }

  @override
  Future<void> close() async {
    await _locations.cancel();
    return super.close();
  }
}
