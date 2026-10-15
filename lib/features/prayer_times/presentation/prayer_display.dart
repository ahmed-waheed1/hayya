import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../core/services/user_location.dart';
import '../../../core/theme/hayya_colors.dart';
import '../../../core/utils/localized_format.dart';
import '../../../core/widgets/hayya_icon.dart';
import '../../../generated/locale_keys.g.dart';
import '../domain/entities/hijri_date.dart';
import '../domain/entities/prayer.dart';

/// How a [Prayer] is shown: name, icon and Home header period.
extension PrayerDisplay on Prayer {
  String get localizedName => switch (this) {
    Prayer.fajr => LocaleKeys.prayers_fajr,
    Prayer.sunrise => LocaleKeys.prayers_sunrise,
    Prayer.dhuhr => LocaleKeys.prayers_dhuhr,
    Prayer.asr => LocaleKeys.prayers_asr,
    Prayer.maghrib => LocaleKeys.prayers_maghrib,
    Prayer.isha => LocaleKeys.prayers_isha,
  }.tr();

  HayyaIconData get icon => switch (this) {
    Prayer.fajr => HayyaIcons.fajr,
    Prayer.sunrise => HayyaIcons.sunrise,
    Prayer.dhuhr => HayyaIcons.dhuhr,
    Prayer.asr => HayyaIcons.asr,
    Prayer.maghrib => HayyaIcons.maghrib,
    Prayer.isha => HayyaIcons.isha,
  };

  /// The header palette while this prayer is current: dawn, daylight
  /// (sunrise to Asr), sunset, night.
  PrayerPeriod get period => switch (this) {
    Prayer.fajr => PrayerPeriod.fajr,
    Prayer.sunrise || Prayer.dhuhr || Prayer.asr => PrayerPeriod.dhuhr,
    Prayer.maghrib => PrayerPeriod.maghrib,
    Prayer.isha => PrayerPeriod.isha,
  };
}

const _hijriMonths = [
  LocaleKeys.dates_hijri_months_muharram,
  LocaleKeys.dates_hijri_months_safar,
  LocaleKeys.dates_hijri_months_rabi_al_awwal,
  LocaleKeys.dates_hijri_months_rabi_al_thani,
  LocaleKeys.dates_hijri_months_jumada_al_ula,
  LocaleKeys.dates_hijri_months_jumada_al_akhirah,
  LocaleKeys.dates_hijri_months_rajab,
  LocaleKeys.dates_hijri_months_shaban,
  LocaleKeys.dates_hijri_months_ramadan,
  LocaleKeys.dates_hijri_months_shawwal,
  LocaleKeys.dates_hijri_months_dhu_al_qadah,
  LocaleKeys.dates_hijri_months_dhu_al_hijjah,
];

extension HijriDateDisplay on HijriDate {
  /// "4 Jumada al-Ula 1448 AH" / "٤ جمادى الأولى ١٤٤٨ هـ".
  String format(LocalizedFormat format) => format.digits(
    LocaleKeys.dates_hijri.tr(
      args: ['$day', _hijriMonths[month - 1].tr(), '$year'],
    ),
  );
}

extension UserLocationDisplay on UserLocation {
  /// The city in the app's language, or "Current location" when the place
  /// couldn't be named (offline on first fix).
  String cityName(Locale locale) =>
      placeName(locale.languageCode)?.city ??
      LocaleKeys.home_current_location.tr();

  /// "Cairo, Egypt", or whichever part is known.
  String placeLabel(Locale locale) {
    final name = placeName(locale.languageCode);
    final parts = [name?.city, name?.country].nonNulls.toList();
    return switch (parts) {
      [final city, final country] => LocaleKeys.location_place.tr(
        args: [city, country],
      ),
      [final only] => only,
      _ => LocaleKeys.home_current_location.tr(),
    };
  }
}
