import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/prayer_calculation_settings.dart';
import '../domain/repositories/prayer_settings_repository.dart';

/// Stores [PrayerCalculationSettings] in shared preferences. Unset or
/// unknown values fall back to the defaults (Egyptian, Shafi'i).
class PrayerSettingsRepositoryImpl implements PrayerSettingsRepository {
  PrayerSettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final _changes = StreamController<PrayerCalculationSettings>.broadcast();

  static const _methodKey = 'calculation_method';
  static const _madhabKey = 'asr_madhab';

  @override
  PrayerCalculationSettings get settings {
    const defaults = PrayerCalculationSettings();
    return PrayerCalculationSettings(
      method:
          CalculationMethod.values.asNameMap()[_prefs.getString(_methodKey)] ??
          defaults.method,
      madhab:
          AsrMadhab.values.asNameMap()[_prefs.getString(_madhabKey)] ??
          defaults.madhab,
    );
  }

  @override
  Stream<PrayerCalculationSettings> get changes => _changes.stream;

  @override
  Future<void> save(PrayerCalculationSettings settings) async {
    await _prefs.setString(_methodKey, settings.method.name);
    await _prefs.setString(_madhabKey, settings.madhab.name);
    _changes.add(settings);
  }
}
