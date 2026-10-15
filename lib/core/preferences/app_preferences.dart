import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user choices that must survive a restart.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'theme_mode';
  static const _languageCodeKey = 'language_code';

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString(_themeModeKey)] ??
      ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  /// Null until the user picks a language; the device locale applies then.
  String? get languageCode => _prefs.getString(_languageCodeKey);

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(_languageCodeKey, code);
  }
}
