import '../../../../core/services/user_location.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../entities/adhan_preferences.dart';
import '../entities/planned_notification.dart';

/// Which notifications should be pending at [now]: each enabled prayer's
/// adhan, and its reminder when on, over the next [days] days.
///
/// The app reschedules whenever it opens, so the horizon only has to last
/// until the next visit.
class PlanAdhanNotifications {
  const PlanAdhanNotifications(this._repository);

  final PrayerTimesRepository _repository;

  /// Today plus the six days after it.
  static const days = 7;

  /// Soonest first, all after [now], at most [limit] long. If [limit] cuts
  /// between a reminder and its adhan, the lone reminder is dropped too.
  List<PlannedNotification> call({
    required DateTime now,
    required GeoCoordinates coordinates,
    required PrayerCalculationSettings settings,
    required AdhanPreferences preferences,
    required int limit,
  }) {
    final reminder = preferences.reminder;
    final planned = <PlannedNotification>[];
    for (var offset = 0; offset < days; offset++) {
      final date = DateTime(now.year, now.month, now.day + offset);
      final day = _repository.timesFor(date, coordinates, settings);
      for (final entry in day.times) {
        if (!preferences.isEnabled(entry.prayer)) continue;
        PlannedNotification at(NotificationKind kind, DateTime time) =>
            PlannedNotification(
              prayer: entry.prayer,
              kind: kind,
              prayerTime: entry.time,
              at: time,
            );
        if (reminder != null) {
          final remindAt = entry.time.subtract(reminder);
          if (remindAt.isAfter(now)) {
            planned.add(at(NotificationKind.reminder, remindAt));
          }
        }
        if (entry.time.isAfter(now)) {
          planned.add(at(NotificationKind.adhan, entry.time));
        }
      }
    }

    planned.sort((a, b) => a.at.compareTo(b.at));
    final kept = planned.take(limit).toList();
    if (kept.lastOrNull?.kind == NotificationKind.reminder) kept.removeLast();
    return kept;
  }
}
