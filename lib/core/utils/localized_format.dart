import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../generated/locale_keys.g.dart';
import '../preferences/display_preferences.dart';
import '../services/user_location.dart';

/// Numbers, clock times and dates in the app's language and the user's
/// [DisplayPreferences]. Arabic uses Arabic-Indic digits (٠١٢…) unless the
/// user picked Western ones.
///
/// In widgets, use `context.format`, which rebuilds the widget when the
/// language or the preferences change.
class LocalizedFormat extends Equatable {
  const LocalizedFormat(
    this.locale, {
    this.numerals = Numerals.arabicIndic,
    this.use24Hour = false,
  });

  final Locale locale;
  final Numerals numerals;
  final bool use24Hour;

  static const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static final _latinDigit = RegExp('[0-9]');

  /// A decimal point between digits ("19.5"), which Arabic-Indic writes as
  /// "١٩٫٥".
  static final _decimalPoint = RegExp(r'(?<=[0-9])\.(?=[0-9])');

  bool get _usesArabicIndic =>
      locale.languageCode == 'ar' && numerals == Numerals.arabicIndic;

  /// Replaces Latin digits (and decimal points) in [text] with the
  /// locale's.
  String digits(String text) => _usesArabicIndic
      ? text
            .replaceAll(_decimalPoint, '٫')
            .replaceAllMapped(
              _latinDigit,
              (m) => _arabicIndic[m[0]!.codeUnitAt(0) - 0x30],
            )
      : text;

  String number(num value) => digits(value.toString());

  /// "+5" / "−3" / "0": an adjustment, with a real minus sign.
  String signed(int value) => digits(switch (value) {
    > 0 => '+$value',
    < 0 => '−${-value}',
    _ => '0',
  });

  /// Clock time split into digits ("5:28") and the AM/PM marker, which the
  /// design sets smaller. The marker is empty on 24-hour clocks.
  ({String time, String meridiem}) clock(DateTime time) {
    final minutes = time.minute.toString().padLeft(2, '0');
    if (use24Hour) {
      final hours = time.hour.toString().padLeft(2, '0');
      return (time: digits('$hours:$minutes'), meridiem: '');
    }
    final hour12 = (time.hour + 11) % 12 + 1;
    return (
      time: digits('$hour12:$minutes'),
      meridiem: (time.hour < 12 ? LocaleKeys.dates_am : LocaleKeys.dates_pm)
          .tr(),
    );
  }

  /// "01:41:18". Rounds up so it only reads 00:00:00 once time is up.
  String countdown(Duration remaining) {
    final total = (remaining.inMilliseconds / 1000).ceil().clamp(0, 359999);
    String two(int n) => n.toString().padLeft(2, '0');
    return digits(
      '${two(total ~/ 3600)}:${two(total % 3600 ~/ 60)}:${two(total % 60)}',
    );
  }

  /// "Thursday, 15 October 2026"; the pattern lives in the translations.
  String gregorianDate(DateTime date) {
    final format = DateFormat(
      LocaleKeys.dates_gregorian_pattern.tr(),
      locale.toLanguageTag(),
    )..useNativeDigits = false;
    return digits(format.format(date));
  }

  /// "30.04°N 31.24°E".
  String coordinates(GeoCoordinates at) {
    String part(double value, String positive, String negative) =>
        LocaleKeys.location_coordinate.tr(
          args: [
            digits(value.abs().toStringAsFixed(2)),
            (value < 0 ? negative : positive).tr(),
          ],
        );
    return LocaleKeys.location_coordinates.tr(
      args: [
        part(at.latitude, LocaleKeys.location_north, LocaleKeys.location_south),
        part(at.longitude, LocaleKeys.location_east, LocaleKeys.location_west),
      ],
    );
  }

  /// "3 minutes ago"-style age of [then], for "Last updated …".
  String lastUpdated(DateTime then, DateTime now) {
    final age = now.difference(then);
    final text = switch (age) {
      _ when age.inMinutes < 1 => LocaleKeys.location_updated_just_now.tr(),
      _ when age.inHours < 1 => LocaleKeys.location_updated_minutes.plural(
        age.inMinutes,
      ),
      _ when age.inDays < 1 => LocaleKeys.location_updated_hours.plural(
        age.inHours,
      ),
      _ => LocaleKeys.location_updated_days.plural(age.inDays),
    };
    return digits(text);
  }

  @override
  List<Object?> get props => [locale, numerals, use24Hour];
}

extension LocalizedFormatContext on BuildContext {
  /// Formatting for the app's language, the user's [DisplayPreferences]
  /// and the device's 24-hour setting. The calling widget rebuilds when
  /// any of them changes.
  LocalizedFormat get format {
    final preferences = DisplayPreferencesScope.of(this);
    return LocalizedFormat(
      locale,
      numerals: preferences.numerals,
      use24Hour: preferences.use24Hour(
        deviceUses24Hour: MediaQuery.alwaysUse24HourFormatOf(this),
      ),
    );
  }
}
