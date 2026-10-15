import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/prayer.dart';
import '../domain/entities/prayer_calculation_settings.dart';
import '../domain/repositories/prayer_settings_repository.dart';

/// Stores [PrayerCalculationSettings] in shared preferences. Unset or
/// unknown values fall back to the defaults (Egyptian, Shafi'i, middle of
/// the night, no adjustments).
class PrayerSettingsRepositoryImpl implements PrayerSettingsRepository {
  PrayerSettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final _changes = StreamController<PrayerCalculationSettings>.broadcast();

  static const _methodKey = 'calculation_method';
  static const _madhabKey = 'asr_madhab';
  static const _highLatitudeKey = 'high_latitude_rule';

  /// One int per prayer, e.g. `adjustment_fajr`.
  static String _adjustmentKey(Prayer prayer) => 'adjustment_${prayer.name}';

  @override
  PrayerCalculationSettings get settings {
    const defaults = PrayerCalculationSettings();
    const max = PrayerCalculationSettings.maxAdjustment;
    return PrayerCalculationSettings(
      method:
          CalculationMethod.values.asNameMap()[_prefs.getString(_methodKey)] ??
          defaults.method,
      madhab:
          AsrMadhab.values.asNameMap()[_prefs.getString(_madhabKey)] ??
          defaults.madhab,
      highLatitudeRule:
          HighLatitudeRule.values.asNameMap()[_prefs.getString(
            _highLatitudeKey,
          )] ??
          defaults.highLatitudeRule,
      adjustments: {
        for (final prayer in Prayer.values)
          if (_prefs.getInt(_adjustmentKey(prayer)) case final minutes?
              when minutes != 0 && minutes.abs() <= max)
            prayer: minutes,
      },
    );
  }

  @override
  Stream<PrayerCalculationSettings> get changes => _changes.stream;

  @override
  Future<void> save(PrayerCalculationSettings settings) async {
    await _prefs.setString(_methodKey, settings.method.name);
    await _prefs.setString(_madhabKey, settings.madhab.name);
    await _prefs.setString(_highLatitudeKey, settings.highLatitudeRule.name);
    for (final prayer in Prayer.values) {
      final minutes = settings.adjustmentFor(prayer);
      if (minutes == 0) {
        await _prefs.remove(_adjustmentKey(prayer));
      } else {
        await _prefs.setInt(_adjustmentKey(prayer), minutes);
      }
    }
    _changes.add(settings);
  }
}
