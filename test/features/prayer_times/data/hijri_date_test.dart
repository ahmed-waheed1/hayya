import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/data/hijri_calendar_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/hijri_date.dart';
import 'package:hayya/features/prayer_times/domain/usecases/get_hijri_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Hijri date (Umm al-Qura)', () {
    late HijriCalendarRepositoryImpl calendar;
    late GetHijriDate getHijriDate;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      calendar = HijriCalendarRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      getHijriDate = GetHijriDate(calendar);
    });

    test('1 Ramadan 1447 is 18 February 2026', () {
      expect(
        getHijriDate(DateTime(2026, 2, 18)),
        const HijriDate(year: 1447, month: 9, day: 1),
      );
    });

    test('15 October 2026', () {
      expect(
        getHijriDate(DateTime(2026, 10, 15)),
        const HijriDate(year: 1448, month: 5, day: 4),
      );
    });

    test('the time of day does not change the date', () {
      expect(
        getHijriDate(DateTime(2026, 10, 15, 23, 59)),
        getHijriDate(DateTime(2026, 10, 15)),
      );
    });

    test('the adjustment shifts the date by whole days', () async {
      await calendar.saveAdjustmentDays(1);
      expect(
        getHijriDate(DateTime(2026, 10, 15)),
        const HijriDate(year: 1448, month: 5, day: 5),
      );

      await calendar.saveAdjustmentDays(-2);
      expect(
        getHijriDate(DateTime(2026, 10, 15)),
        const HijriDate(year: 1448, month: 5, day: 2),
      );
    });

    test('the adjustment crosses month ends', () async {
      // 1 Ramadan 1447 is 18 February 2026, so a day earlier is Sha'ban.
      await calendar.saveAdjustmentDays(-1);
      expect(getHijriDate(DateTime(2026, 2, 18)).month, 8);
    });

    test('the adjustment stays within ±2 days and survives a reload', () async {
      final changes = <int>[];
      calendar.adjustmentChanges.listen(changes.add);

      await calendar.saveAdjustmentDays(5);
      expect(calendar.adjustmentDays, 2);
      final reloaded = HijriCalendarRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.adjustmentDays, 2);

      await calendar.saveAdjustmentDays(-9);
      await pumpEventQueue();
      expect(calendar.adjustmentDays, -2);
      expect(changes, [2, -2]);
    });

    test('an out-of-range stored adjustment is ignored', () async {
      SharedPreferences.setMockInitialValues({'hijri_adjustment_days': 7});
      final stored = HijriCalendarRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      expect(stored.adjustmentDays, 0);
    });
  });
}
