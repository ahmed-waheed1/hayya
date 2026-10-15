import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../prayer_times/domain/entities/prayer.dart';
import '../domain/entities/adhan_preferences.dart';
import '../domain/repositories/adhan_preferences_repository.dart';

/// Stores [AdhanPreferences] in shared preferences. Unset or unknown
/// values fall back to the defaults (every adhan on, no reminder, alarm
/// volume).
class AdhanPreferencesRepositoryImpl implements AdhanPreferencesRepository {
  AdhanPreferencesRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final _changes = StreamController<AdhanPreferences>.broadcast();

  static const _enabledKey = 'adhan_prayers';
  static const _reminderOnKey = 'adhan_reminder_on';
  static const _reminderMinutesKey = 'adhan_reminder_minutes';
  static const _volumeKey = 'adhan_volume';
  static const _promptedKey = 'notification_permission_prompted';

  @override
  AdhanPreferences get preferences {
    const defaults = AdhanPreferences();
    final names = _prefs.getStringList(_enabledKey);
    final minutes = _prefs.getInt(_reminderMinutesKey);
    return AdhanPreferences(
      enabled: names == null
          ? defaults.enabled
          : {for (final name in names) ?Prayer.values.asNameMap()[name]}
                .where((p) => p.isObligatory)
                .toSet(),
      reminderOn: _prefs.getBool(_reminderOnKey) ?? defaults.reminderOn,
      reminderMinutes: AdhanPreferences.reminderOptions.contains(minutes)
          ? minutes!
          : defaults.reminderMinutes,
      volume:
          AdhanVolume.values.asNameMap()[_prefs.getString(_volumeKey)] ??
          defaults.volume,
    );
  }

  @override
  Stream<AdhanPreferences> get changes => _changes.stream;

  @override
  Future<void> save(AdhanPreferences preferences) async {
    await _prefs.setStringList(_enabledKey, [
      for (final prayer in Prayer.values)
        if (preferences.enabled.contains(prayer)) prayer.name,
    ]);
    await _prefs.setBool(_reminderOnKey, preferences.reminderOn);
    await _prefs.setInt(_reminderMinutesKey, preferences.reminderMinutes);
    await _prefs.setString(_volumeKey, preferences.volume.name);
    _changes.add(preferences);
  }

  @override
  bool get permissionPrompted => _prefs.getBool(_promptedKey) ?? false;

  @override
  Future<void> markPermissionPrompted() async {
    await _prefs.setBool(_promptedKey, true);
  }
}
