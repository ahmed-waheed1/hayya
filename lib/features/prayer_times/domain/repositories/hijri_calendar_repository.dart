import '../entities/hijri_date.dart';

abstract interface class HijriCalendarRepository {
  HijriDate fromGregorian(DateTime date);
}
