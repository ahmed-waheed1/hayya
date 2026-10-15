import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/preferences/app_preferences.dart';
import 'package:hayya/core/theme/theme_mode_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return AppPreferences(await SharedPreferences.getInstance());
  }

  test('defaults: system theme, no language chosen', () async {
    final prefs = await prefsWith({});
    expect(prefs.themeMode, ThemeMode.system);
    expect(prefs.languageCode, isNull);
  });

  test('unknown stored theme falls back to system', () async {
    final prefs = await prefsWith({'theme_mode': 'sepia'});
    expect(prefs.themeMode, ThemeMode.system);
  });

  test('theme and language survive a reload', () async {
    final prefs = await prefsWith({});
    await prefs.setThemeMode(ThemeMode.dark);
    await prefs.setLanguageCode('ar');

    final reloaded = AppPreferences(await SharedPreferences.getInstance());
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.languageCode, 'ar');
  });

  test('ThemeModeCubit starts from and writes to preferences', () async {
    final prefs = await prefsWith({'theme_mode': 'light'});
    final cubit = ThemeModeCubit(prefs);
    expect(cubit.state, ThemeMode.light);

    await cubit.setMode(ThemeMode.dark);
    expect(cubit.state, ThemeMode.dark);
    expect(prefs.themeMode, ThemeMode.dark);
    await cubit.close();
  });
}
