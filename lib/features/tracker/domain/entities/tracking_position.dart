import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/domain/entities/prayer_schedule.dart';
import 'calendar_day.dart';
import 'tracker_data.dart';

/// The prayer day the user is in: [day], and how many of its five prayers
/// have begun ([due]).
///
/// The prayer day runs from Fajr to the next Fajr, so between midnight
/// and Fajr it is still yesterday: Isha prayed then counts for the day it
/// belongs to.
class TrackingPosition extends Equatable {
  TrackingPosition({required DateTime day, this.due}) : day = day.dateOnly;

  /// From today's prayer times.
  factory TrackingPosition.of(PrayerSchedule schedule) {
    final today = schedule.today;
    if (_beforeFajr(schedule)) {
      return TrackingPosition(day: today.date.addDays(-1), due: 5);
    }
    return TrackingPosition(
      day: today.date,
      due: trackedPrayers
          .where((p) => !today[p].time.isAfter(schedule.now))
          .length,
    );
  }

  final DateTime day;

  /// Null when the prayer times aren't known (no location yet). Today
  /// then counts only the prayers already marked.
  final int? due;

  @override
  List<Object?> get props => [day, due];
}

/// Where one of today's prayer rows on Home records to.
class PrayerSlot extends Equatable {
  const PrayerSlot({
    required this.prayer,
    required this.day,
    required this.open,
  });

  final Prayer prayer;

  /// The prayer day the check belongs to.
  final DateTime day;

  /// The prayer's time has begun, so it can be checked. Future prayers
  /// can't.
  final bool open;

  @override
  List<Object?> get props => [prayer, day, open];
}

/// One slot per tracked prayer in today's list.
///
/// Between midnight and Fajr the current prayer is still yesterday's Isha,
/// so the Isha row records to yesterday and stays open; everything else
/// is in the future.
Map<Prayer, PrayerSlot> prayerSlots(PrayerSchedule schedule) {
  final today = schedule.today;
  final beforeFajr = _beforeFajr(schedule);
  return {
    for (final prayer in trackedPrayers)
      prayer: prayer == Prayer.isha && beforeFajr
          ? PrayerSlot(prayer: prayer, day: today.date.addDays(-1), open: true)
          : PrayerSlot(
              prayer: prayer,
              day: today.date,
              open: !today[prayer].time.isAfter(schedule.now),
            ),
  };
}

bool _beforeFajr(PrayerSchedule schedule) =>
    schedule.now.isBefore(schedule.today[Prayer.fajr].time);
