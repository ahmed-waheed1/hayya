import '../../../../core/services/user_location.dart';
import '../entities/prayer_calculation_settings.dart';
import '../entities/prayer_day.dart';
import '../entities/prayer_schedule.dart';
import '../repositories/prayer_times_repository.dart';

/// Today's times, the current prayer and the next one at a given moment.
class GetPrayerSchedule {
  GetPrayerSchedule(this._repository);

  final PrayerTimesRepository _repository;

  /// Days are recalculated only when the date, place or settings change,
  /// so calling this every second for the countdown stays cheap.
  final _days = <DateTime, PrayerDay>{};
  (GeoCoordinates, PrayerCalculationSettings)? _daysKey;

  PrayerSchedule call({
    required DateTime now,
    required GeoCoordinates coordinates,
    required PrayerCalculationSettings settings,
  }) {
    if (_daysKey != (coordinates, settings)) {
      _days.clear();
      _daysKey = (coordinates, settings);
    }

    final dates = [
      for (final offset in [-1, 0, 1])
        DateTime(now.year, now.month, now.day + offset),
    ];
    _days.removeWhere((date, _) => !dates.contains(date));
    final [yesterday, today, tomorrow] = [
      for (final date in dates)
        _days[date] ??= _repository.timesFor(date, coordinates, settings),
    ];

    return PrayerSchedule.resolve(
      now: now,
      yesterday: yesterday,
      today: today,
      tomorrow: tomorrow,
    );
  }
}
