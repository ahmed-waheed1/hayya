import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_preferences.dart';

/// Digits used while the app is in Arabic. English always uses Western.
enum Numerals {
  /// ٠١٢٣٤٥٦٧٨٩, as in the design.
  arabicIndic,

  /// 0123456789.
  western,
}

enum TimeFormat { twelveHour, twentyFourHour }

/// How numbers and clock times are written.
class DisplayPreferences extends Equatable {
  const DisplayPreferences({
    this.numerals = Numerals.arabicIndic,
    this.timeFormat,
  });

  final Numerals numerals;

  /// Null until the user picks one; the device's 12/24-hour setting
  /// applies then.
  final TimeFormat? timeFormat;

  /// [timeFormat], or the device's setting when none was picked.
  bool use24Hour({required bool deviceUses24Hour}) => switch (timeFormat) {
    TimeFormat.twelveHour => false,
    TimeFormat.twentyFourHour => true,
    null => deviceUses24Hour,
  };

  @override
  List<Object?> get props => [numerals, timeFormat];
}

/// The user's [DisplayPreferences], persisted in [AppPreferences].
class DisplayPreferencesCubit extends Cubit<DisplayPreferences> {
  DisplayPreferencesCubit(this._prefs) : super(_prefs.displayPreferences);

  final AppPreferences _prefs;

  Future<void> setNumerals(Numerals numerals) async {
    emit(DisplayPreferences(numerals: numerals, timeFormat: state.timeFormat));
    await _prefs.setNumerals(numerals);
  }

  Future<void> setTimeFormat(TimeFormat format) async {
    emit(DisplayPreferences(numerals: state.numerals, timeFormat: format));
    await _prefs.setTimeFormat(format);
  }
}

/// Makes [DisplayPreferences] available to `context.format`, so every
/// widget that formats a number rebuilds when they change.
///
/// Sits above `MaterialApp` in `app.dart`. Without one (widget tests of a
/// single component) the defaults apply.
class DisplayPreferencesScope extends InheritedWidget {
  const DisplayPreferencesScope({
    super.key,
    required this.preferences,
    required super.child,
  });

  final DisplayPreferences preferences;

  static DisplayPreferences of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DisplayPreferencesScope>()
          ?.preferences ??
      const DisplayPreferences();

  @override
  bool updateShouldNotify(DisplayPreferencesScope oldWidget) =>
      preferences != oldWidget.preferences;
}
