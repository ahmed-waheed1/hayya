import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:hayya/features/notifications/domain/entities/adhan_preferences.dart';
import 'package:hayya/features/notifications/domain/entities/planned_notification.dart';
import 'package:hayya/features/notifications/domain/usecases/plan_adhan_notifications.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:hayya/features/prayer_times/domain/repositories/prayer_times_repository.dart';

import '../../../helpers/prayer_fixtures.dart';

void main() {
  const plan = PlanAdhanNotifications(_repository);
  const coordinates = GeoCoordinates(30.0444, 31.2357);
  final midday = DateTime(2026, 10, 15, 13);

  List<PlannedNotification> planAt(
    DateTime now, {
    AdhanPreferences preferences = const AdhanPreferences(),
    int limit = 500,
  }) => plan(
    now: now,
    coordinates: coordinates,
    settings: const PrayerCalculationSettings(),
    preferences: preferences,
    limit: limit,
  );

  test('every adhan from now through the next 6 days, never Sunrise', () {
    final planned = planAt(midday);

    // Today's Asr, Maghrib and Isha, then 5 a day for 6 more days.
    expect(planned, hasLength(3 + 6 * 5));
    expect(planned.every((n) => n.kind == NotificationKind.adhan), isTrue);
    expect(planned.any((n) => n.prayer == Prayer.sunrise), isFalse);
    expect(planned.first.prayer, Prayer.asr);
    expect(planned.first.at, DateTime(2026, 10, 15, 15, 30));
    expect(planned.last.at, DateTime(2026, 10, 21, 19, 30));
    expect(planned.every((n) => n.at.isAfter(midday)), isTrue);
  });

  test('a longer horizon plans further ahead, still capped by the limit', () {
    List<PlannedNotification> over(int days, {int limit = 500}) => plan(
      now: midday,
      coordinates: coordinates,
      settings: const PrayerCalculationSettings(),
      preferences: const AdhanPreferences(),
      limit: limit,
      days: days,
    );

    expect(over(14), hasLength(3 + 13 * 5));
    expect(over(14).last.at, DateTime(2026, 10, 28, 19, 30));
    // iOS: 64 days asked for, the 64 slots run out after under 13 days.
    final capped = over(64, limit: 64);
    expect(capped, hasLength(64));
    expect(capped.last.at.isAfter(DateTime(2026, 10, 27)), isTrue);
  });

  test('results are soonest first', () {
    final planned = planAt(
      midday,
      preferences: const AdhanPreferences(reminderOn: true),
    );
    for (var i = 1; i < planned.length; i++) {
      expect(planned[i].at.isAfter(planned[i - 1].at), isTrue);
    }
  });

  test('a prayer switched off is never scheduled', () {
    final planned = planAt(
      midday,
      preferences: const AdhanPreferences().withPrayer(Prayer.fajr, on: false),
    );
    expect(planned.any((n) => n.prayer == Prayer.fajr), isFalse);
    expect(planned, hasLength(3 + 6 * 4));
  });

  test('with every prayer off, nothing is scheduled', () {
    expect(
      planAt(midday, preferences: const AdhanPreferences(enabled: {})),
      isEmpty,
    );
  });

  test('an adhan exactly at now is already past', () {
    final planned = planAt(DateTime(2026, 10, 15, 15, 30));
    expect(planned.first.prayer, Prayer.maghrib);
  });

  test('the reminder comes its lead time before each adhan', () {
    final planned = planAt(
      midday,
      preferences: const AdhanPreferences(
        reminderOn: true,
        reminderMinutes: 15,
      ),
    );
    expect(planned, hasLength(2 * (3 + 6 * 5)));
    final [reminder, adhan, ...] = planned;
    expect(reminder.kind, NotificationKind.reminder);
    expect(reminder.prayer, Prayer.asr);
    expect(reminder.at, DateTime(2026, 10, 15, 15, 15));
    expect(reminder.prayerTime, DateTime(2026, 10, 15, 15, 30));
    expect(adhan.kind, NotificationKind.adhan);
    expect(adhan.at, reminder.prayerTime);
  });

  test('a reminder already past still leaves its adhan', () {
    final planned = planAt(
      DateTime(2026, 10, 15, 15, 25),
      preferences: const AdhanPreferences(reminderOn: true),
    );
    expect(planned.first.kind, NotificationKind.adhan);
    expect(planned.first.prayer, Prayer.asr);
    expect(planned[1].kind, NotificationKind.reminder);
    expect(planned[1].prayer, Prayer.maghrib);
  });

  test('the reminder stays off by default', () {
    expect(const AdhanPreferences().reminder, isNull);
    expect(
      planAt(midday).where((n) => n.kind == NotificationKind.reminder),
      isEmpty,
    );
  });

  group('iOS 64-notification cap', () {
    test('keeps the soonest 64', () {
      final all = planAt(
        midday,
        preferences: const AdhanPreferences(reminderOn: true),
      );
      final capped = planAt(
        midday,
        preferences: const AdhanPreferences(reminderOn: true),
        limit: 64,
      );
      expect(all.length, greaterThan(64));
      expect(capped, hasLength(64));
      expect(capped, all.take(64).toList());
    });

    test('never ends on a reminder whose adhan was cut', () {
      // Asr reminder, Asr, Maghrib reminder, Maghrib, Isha reminder: the
      // 5th is a reminder without its adhan.
      final capped = planAt(
        midday,
        preferences: const AdhanPreferences(reminderOn: true),
        limit: 5,
      );
      expect(capped, hasLength(4));
      expect(capped.last.kind, NotificationKind.adhan);
      expect(capped.last.prayer, Prayer.maghrib);
    });
  });

  group('ids', () {
    test('are unique', () {
      final planned = planAt(
        midday,
        preferences: const AdhanPreferences(reminderOn: true),
      );
      expect(planned.map((n) => n.id).toSet(), hasLength(planned.length));
    });

    test('are stable when replanned later', () {
      final earlier = planAt(midday);
      final later = planAt(DateTime(2026, 10, 17, 9));
      final isha18 = DateTime(2026, 10, 18, 19, 30);
      int idOf(List<PlannedNotification> plan) =>
          plan.firstWhere((n) => n.at == isha18).id;
      expect(idOf(later), idOf(earlier));
    });

    test('fit in a 32-bit int', () {
      final far = planAt(DateTime(2099, 12, 31, 13));
      expect(far.every((n) => n.id > 0 && n.id < 0x7fffffff), isTrue);
    });
  });
}

const _repository = _FixedTimes();

/// Every day: Fajr 05:00, Sunrise 06:30, Dhuhr 12:00, Asr 15:30,
/// Maghrib 18:00, Isha 19:30.
class _FixedTimes implements PrayerTimesRepository {
  const _FixedTimes();

  @override
  PrayerDay timesFor(
    DateTime date,
    GeoCoordinates coordinates,
    PrayerCalculationSettings settings,
  ) => fixedDay(date);
}
