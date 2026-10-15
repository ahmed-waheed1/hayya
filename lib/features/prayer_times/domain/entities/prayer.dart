import 'package:equatable/equatable.dart';

/// The six daily times, in the order they occur.
enum Prayer {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  /// Sunrise marks the end of Fajr's time. It has no adhan and isn't
  /// tracked.
  bool get isObligatory => this != sunrise;
}

/// One [prayer] at a point in time.
class PrayerTime extends Equatable {
  const PrayerTime(this.prayer, this.time);

  final Prayer prayer;
  final DateTime time;

  @override
  List<Object?> get props => [prayer, time];
}
