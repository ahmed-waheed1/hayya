import 'package:easy_localization/easy_localization.dart';

import '../../../core/utils/localized_format.dart';
import '../../../generated/locale_keys.g.dart';
import '../../prayer_times/presentation/prayer_display.dart';
import '../domain/entities/timetable_month.dart';

extension TimetableDayDisplay on TimetableDay {
  /// "Th" / "خمي".
  String get weekdayShort => switch (date.weekday) {
    DateTime.monday => LocaleKeys.timetable_weekdays_mon,
    DateTime.tuesday => LocaleKeys.timetable_weekdays_tue,
    DateTime.wednesday => LocaleKeys.timetable_weekdays_wed,
    DateTime.thursday => LocaleKeys.timetable_weekdays_thu,
    DateTime.friday => LocaleKeys.timetable_weekdays_fri,
    DateTime.saturday => LocaleKeys.timetable_weekdays_sat,
    _ => LocaleKeys.timetable_weekdays_sun,
  }.tr();
}

extension TimetableMonthDisplay on TimetableMonth {
  /// The Hijri months the Gregorian month spans: "Rabi al-Thani – Jumada
  /// al-Ula 1448", "Dhu al-Hijjah 1447 – Muharram 1448" across a Hijri
  /// year, or just "Rajab 1447" for a February inside one Hijri month.
  String hijriRange(LocalizedFormat format) {
    final first = firstHijri;
    final last = lastHijri;
    final text = (first.year, first.month) == (last.year, last.month)
        ? LocaleKeys.timetable_hijri_month.tr(
            args: [first.monthName, '${first.year}'],
          )
        : first.year == last.year
        ? LocaleKeys.timetable_hijri_range_same_year.tr(
            args: [first.monthName, last.monthName, '${last.year}'],
          )
        : LocaleKeys.timetable_hijri_range.tr(
            args: [
              first.monthName,
              '${first.year}',
              last.monthName,
              '${last.year}',
            ],
          );
    return format.digits(text);
  }
}
