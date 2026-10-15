import '../entities/hijri_date.dart';

abstract interface class HijriCalendarRepository {
  /// The Hijri date for a Gregorian day, with [adjustmentDays] applied.
  HijriDate fromGregorian(DateTime date);

  /// Days added to the calculated date, from -[maxAdjustmentDays] to
  /// +[maxAdjustmentDays], for when the local moon sighting differs.
  int get adjustmentDays;

  /// Emits each time [saveAdjustmentDays] stores a new value.
  Stream<int> get adjustmentChanges;

  Future<void> saveAdjustmentDays(int days);
}

const maxAdjustmentDays = 2;
