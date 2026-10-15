import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

import '../../generated/locale_keys.g.dart';

/// Numbers, clock times and dates in the app's language. Arabic uses
/// Arabic-Indic digits (٠١٢…), as in the design.
abstract final class LocalizedFormat {
  static const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static final _latinDigit = RegExp('[0-9]');

  /// Replaces Latin digits in [text] with the locale's digits.
  static String digits(String text, Locale locale) =>
      locale.languageCode == 'ar'
      ? text.replaceAllMapped(
          _latinDigit,
          (m) => _arabicIndic[m[0]!.codeUnitAt(0) - 0x30],
        )
      : text;

  static String number(num value, Locale locale) =>
      digits(value.toString(), locale);

  /// Clock time split into digits ("5:28") and the AM/PM marker, which the
  /// design sets smaller. The marker is empty on 24-hour clocks.
  static ({String time, String meridiem}) clock(
    DateTime time,
    Locale locale, {
    required bool use24Hour,
  }) {
    final minutes = time.minute.toString().padLeft(2, '0');
    if (use24Hour) {
      final hours = time.hour.toString().padLeft(2, '0');
      return (time: digits('$hours:$minutes', locale), meridiem: '');
    }
    final hour12 = (time.hour + 11) % 12 + 1;
    return (
      time: digits('$hour12:$minutes', locale),
      meridiem: (time.hour < 12 ? LocaleKeys.dates_am : LocaleKeys.dates_pm)
          .tr(),
    );
  }

  /// "01:41:18". Rounds up so it only reads 00:00:00 once time is up.
  static String countdown(Duration remaining, Locale locale) {
    final total = (remaining.inMilliseconds / 1000).ceil().clamp(0, 359999);
    String two(int n) => n.toString().padLeft(2, '0');
    return digits(
      '${two(total ~/ 3600)}:${two(total % 3600 ~/ 60)}:${two(total % 60)}',
      locale,
    );
  }

  /// "Thursday, 15 October 2026"; the pattern lives in the translations.
  static String gregorianDate(DateTime date, Locale locale) {
    final format = DateFormat(
      LocaleKeys.dates_gregorian_pattern.tr(),
      locale.toLanguageTag(),
    )..useNativeDigits = false;
    return digits(format.format(date), locale);
  }

  /// "3 minutes ago"-style age of [then], for "Last updated …".
  static String lastUpdated(DateTime then, DateTime now, Locale locale) {
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
    return digits(text, locale);
  }
}
