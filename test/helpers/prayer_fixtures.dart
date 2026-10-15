import 'package:hayya/features/prayer_times/domain/entities/prayer_day.dart';

/// Fajr 05:00, Sunrise 06:30, Dhuhr 12:00, Asr 15:30, Maghrib 18:00,
/// Isha 19:30 on [date].
PrayerDay fixedDay(DateTime date) {
  DateTime at(int h, int m) => DateTime(date.year, date.month, date.day, h, m);
  return PrayerDay(
    date: date,
    fajr: at(5, 0),
    sunrise: at(6, 30),
    dhuhr: at(12, 0),
    asr: at(15, 30),
    maghrib: at(18, 0),
    isha: at(19, 30),
  );
}
