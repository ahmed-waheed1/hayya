import 'package:equatable/equatable.dart';

import 'prayer.dart';
import 'prayer_day.dart';

/// Where [now] falls in the day: today's times plus the prayer whose time
/// has begun ([current]) and the one that comes next ([next]).
class PrayerSchedule extends Equatable {
  const PrayerSchedule._({
    required this.now,
    required this.today,
    required this.current,
    required this.next,
  });

  /// Places [now] between two consecutive times. [today] must be the day
  /// [now] falls on; the neighbouring days supply the times that
  /// cross midnight.
  ///
  /// - Before today's Fajr, [current] is yesterday's Isha.
  /// - After today's Isha, [next] is tomorrow's Fajr.
  /// - A time that starts exactly at [now] is already [current].
  factory PrayerSchedule.resolve({
    required DateTime now,
    required PrayerDay yesterday,
    required PrayerDay today,
    required PrayerDay tomorrow,
  }) {
    final timeline = [
      yesterday[Prayer.isha],
      ...today.times,
      tomorrow[Prayer.fajr],
    ];
    final started = timeline.lastIndexWhere((t) => !t.time.isAfter(now));
    final i = started.clamp(0, timeline.length - 2);
    return PrayerSchedule._(
      now: now,
      today: today,
      current: timeline[i],
      next: timeline[i + 1],
    );
  }

  final DateTime now;
  final PrayerDay today;
  final PrayerTime current;
  final PrayerTime next;

  /// True when [next] is tomorrow's Fajr.
  bool get nextIsTomorrow => next.time.isAfter(today[Prayer.isha].time);

  /// Time left until [next]; never negative.
  Duration get remaining {
    final left = next.time.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// How much of the [current] → [next] interval has passed, 0–1.
  double get progress {
    final total = next.time.difference(current.time).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = now.difference(current.time).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [now, today, current, next];
}
