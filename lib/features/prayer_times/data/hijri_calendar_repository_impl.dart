import 'dart:async';

import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/hijri_date.dart';
import '../domain/repositories/hijri_calendar_repository.dart';

/// Umm al-Qura conversion from the hijri package, shifted by the user's
/// adjustment (stored in shared preferences). Month names come from our
/// translations, not the package's global language setting.
class HijriCalendarRepositoryImpl implements HijriCalendarRepository {
  HijriCalendarRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;
  final _changes = StreamController<int>.broadcast();

  static const _adjustmentKey = 'hijri_adjustment_days';

  @override
  HijriDate fromGregorian(DateTime date) {
    final hijri = HijriCalendar.fromDate(
      DateTime(date.year, date.month, date.day + adjustmentDays),
    );
    return HijriDate(year: hijri.hYear, month: hijri.hMonth, day: hijri.hDay);
  }

  @override
  int get adjustmentDays {
    final days = _prefs.getInt(_adjustmentKey) ?? 0;
    return days.abs() <= maxAdjustmentDays ? days : 0;
  }

  @override
  Stream<int> get adjustmentChanges => _changes.stream;

  @override
  Future<void> saveAdjustmentDays(int days) async {
    final clamped = days.clamp(-maxAdjustmentDays, maxAdjustmentDays);
    await _prefs.setInt(_adjustmentKey, clamped);
    _changes.add(clamped);
  }
}
