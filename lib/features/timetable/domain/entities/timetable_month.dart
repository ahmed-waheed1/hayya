import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/hijri_date.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';

/// A Gregorian month, as `(year, month)` with [month] 1–12.
class CalendarMonth extends Equatable implements Comparable<CalendarMonth> {
  const CalendarMonth(this.year, this.month)
    : assert(month >= 1 && month <= 12);

  CalendarMonth.of(DateTime date) : this(date.year, date.month);

  final int year;
  final int month;

  /// [months] later (or earlier when negative), across years as needed.
  CalendarMonth shift(int months) {
    final index = year * 12 + (month - 1) + months;
    return CalendarMonth(index ~/ 12, index % 12 + 1);
  }

  CalendarMonth get next => shift(1);
  CalendarMonth get previous => shift(-1);

  /// Local midnight of the first day.
  DateTime get firstDay => DateTime(year, month);

  int get length => DateTime(year, month + 1, 0).day;

  /// Every day's local midnight. Built from calendar fields rather than by
  /// adding 24-hour durations, which drift by an hour across a DST change.
  List<DateTime> get days => [
    for (var day = 1; day <= length; day++) DateTime(year, month, day),
  ];

  bool contains(DateTime date) => date.year == year && date.month == month;

  @override
  int compareTo(CalendarMonth other) =>
      (year * 12 + month).compareTo(other.year * 12 + other.month);

  @override
  List<Object?> get props => [year, month];
}

/// One row of the timetable: the day's six times and its Hijri date.
class TimetableDay extends Equatable {
  const TimetableDay({required this.times, required this.hijri});

  final PrayerDay times;

  /// With the user's Hijri adjustment applied.
  final HijriDate hijri;

  DateTime get date => times.date;

  @override
  List<Object?> get props => [times, hijri];
}

/// Every day of [month], in order.
class TimetableMonth extends Equatable {
  const TimetableMonth({required this.month, required this.days});

  final CalendarMonth month;
  final List<TimetableDay> days;

  /// The Hijri date of the first and last day. Their months differ except
  /// in a February that falls inside one Hijri month.
  HijriDate get firstHijri => days.first.hijri;
  HijriDate get lastHijri => days.last.hijri;

  /// The row index of [date], or null when it falls outside [month].
  int? indexOf(DateTime date) => month.contains(date) ? date.day - 1 : null;

  @override
  List<Object?> get props => [month, days];
}
