import '../entities/hijri_date.dart';
import '../repositories/hijri_calendar_repository.dart';

/// The Hijri date for a civil (Gregorian) day.
class GetHijriDate {
  const GetHijriDate(this._calendar);

  final HijriCalendarRepository _calendar;

  HijriDate call(DateTime date) =>
      _calendar.fromGregorian(DateTime(date.year, date.month, date.day));
}
