import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../preferences/app_preferences.dart';

/// App-wide light/dark/system choice, persisted in [AppPreferences].
class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit(this._prefs) : super(_prefs.themeMode);

  final AppPreferences _prefs;

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _prefs.setThemeMode(mode);
  }
}
