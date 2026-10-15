import 'package:equatable/equatable.dart';

import 'prayer.dart';

/// All six times for one calendar day.
class PrayerDay extends Equatable {
  PrayerDay({
    required DateTime date,
    required DateTime fajr,
    required DateTime sunrise,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
  }) : date = DateTime(date.year, date.month, date.day),
       times = List.unmodifiable([
         PrayerTime(Prayer.fajr, fajr),
         PrayerTime(Prayer.sunrise, sunrise),
         PrayerTime(Prayer.dhuhr, dhuhr),
         PrayerTime(Prayer.asr, asr),
         PrayerTime(Prayer.maghrib, maghrib),
         PrayerTime(Prayer.isha, isha),
       ]);

  /// Local midnight of the day.
  final DateTime date;

  /// One entry per [Prayer], in [Prayer.values] order.
  final List<PrayerTime> times;

  PrayerTime operator [](Prayer prayer) => times[prayer.index];

  @override
  List<Object?> get props => [date, times];
}
