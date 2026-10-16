import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'display_preferences.dart';

/// App-wide user choices that must survive a restart.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'theme_mode';
  static const _languageCodeKey = 'language_code';
  static const _numeralsKey = 'numerals';
  static const _timeFormatKey = 'time_format';
  static const _onboardingDoneKey = 'onboarding_done';

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

  /// Unset or unknown values fall back to Arabic-Indic digits and the
  /// device's clock.
  DisplayPreferences get displayPreferences => DisplayPreferences(
    numerals:
        Numerals.values.asNameMap()[_prefs.getString(_numeralsKey)] ??
        Numerals.arabicIndic,
    timeFormat: TimeFormat.values.asNameMap()[_prefs.getString(_timeFormatKey)],
  );

  Future<void> setNumerals(Numerals numerals) async {
    await _prefs.setString(_numeralsKey, numerals.name);
  }

  Future<void> setTimeFormat(TimeFormat format) async {
    await _prefs.setString(_timeFormatKey, format.name);
  }

  /// Onboarding was finished or skipped.
  bool get onboardingDone => _prefs.getBool(_onboardingDoneKey) ?? false;

  Future<void> setOnboardingDone() async {
    await _prefs.setBool(_onboardingDoneKey, true);
  }
}
