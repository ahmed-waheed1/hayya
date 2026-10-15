/// Calendar-day arithmetic in local time that doesn't drift across
/// daylight-saving changes (a "day" there can be 23 or 25 hours).
extension CalendarDay on DateTime {
  /// Local midnight of this date.
  DateTime get dateOnly => DateTime(year, month, day);

  /// The date [days] calendar days later (earlier when negative).
  DateTime addDays(int days) => DateTime(year, month, day + days);

  /// Whole calendar days from this date to [other]; negative when [other]
  /// is earlier.
  int daysUntil(DateTime other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;
}
