import '../../../../core/services/user_location.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/repositories/hijri_calendar_repository.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../entities/timetable_month.dart';

/// A month of prayer times and Hijri dates.
///
/// Each day goes through the same [PrayerTimesRepository.timesFor] and
/// [HijriCalendarRepository.fromGregorian] calls Home uses, so the table
/// always agrees with Home for the same place and settings.
class GetMonthTimetable {
  const GetMonthTimetable(this._times, this._hijri);

  final PrayerTimesRepository _times;
  final HijriCalendarRepository _hijri;

  TimetableMonth call(
    CalendarMonth month, {
    required GeoCoordinates coordinates,
    required PrayerCalculationSettings settings,
  }) => TimetableMonth(
    month: month,
    days: [
      for (final date in month.days)
        TimetableDay(
          times: _times.timesFor(date, coordinates, settings),
          hijri: _hijri.fromGregorian(date),
        ),
    ],
  );
}
