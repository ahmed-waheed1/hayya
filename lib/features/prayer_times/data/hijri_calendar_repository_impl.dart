import 'package:hijri/hijri_calendar.dart';

import '../domain/entities/hijri_date.dart';
import '../domain/repositories/hijri_calendar_repository.dart';

/// Umm al-Qura conversion from the hijri package. Month names come from
/// our translations, not the package's global language setting.
class HijriCalendarRepositoryImpl implements HijriCalendarRepository {
  const HijriCalendarRepositoryImpl();

  @override
  HijriDate fromGregorian(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);
    return HijriDate(year: hijri.hYear, month: hijri.hMonth, day: hijri.hDay);
  }
}
