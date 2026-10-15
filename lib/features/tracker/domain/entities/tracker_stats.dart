import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer.dart';
import 'calendar_day.dart';
import 'tracker_data.dart';
import 'tracking_position.dart';

/// The tracker's numbers at one moment.
///
/// Only known days count (see [TrackerData.isKnown]): days before
/// tracking began are never missed. Today is still in progress, so it
/// never breaks the streak and never counts as missed, and only its
/// prayers that have begun count towards the week.
class TrackerStats extends Equatable {
  const TrackerStats({
    required this.streak,
    required this.weekPrayed,
    required this.weekPossible,
    required this.missed,
    required this.missedDays,
  });

  factory TrackerStats.compute(TrackerData data, TrackingPosition at) {
    int prayedOn(DateTime day) => data.prayedOn(day).length;
    final today = at.day;

    // Streak: complete days back from today, or from yesterday while
    // today is still under way.
    var streak = 0;
    var day = prayedOn(today) == trackedPrayers.length
        ? today
        : today.addDays(-1);
    while (data.isKnown(day) && prayedOn(day) == trackedPrayers.length) {
      streak++;
      day = day.addDays(-1);
    }

    // The last seven days, today included.
    var weekPrayed = 0;
    var weekPossible = 0;
    for (var i = 0; i < weekDays; i++) {
      final day = today.addDays(-i);
      if (!data.isKnown(day)) continue;
      final prayed = prayedOn(day);
      weekPrayed += prayed;
      weekPossible += i == 0
          ? math.max(at.due ?? prayed, prayed)
          : trackedPrayers.length;
    }

    // The last 30 days before today.
    final missed = {for (final p in trackedPrayers) p: 0};
    var missedDays = 0;
    for (var i = 1; i <= missedWindow; i++) {
      final day = today.addDays(-i);
      if (!data.isKnown(day)) continue;
      missedDays++;
      final prayed = data.prayedOn(day);
      for (final p in trackedPrayers) {
        if (!prayed.contains(p)) missed[p] = missed[p]! + 1;
      }
    }

    return TrackerStats(
      streak: streak,
      weekPrayed: weekPrayed,
      weekPossible: weekPossible,
      missed: Map.unmodifiable(missed),
      missedDays: missedDays,
    );
  }

  static const weekDays = 7;
  static const missedWindow = 30;

  /// Days in a row with all five prayers.
  final int streak;

  /// Prayers marked in the last seven days, out of [weekPossible].
  final int weekPrayed;
  final int weekPossible;

  /// Missed prayers per tracked prayer over the last [missedWindow] days.
  final Map<Prayer, int> missed;

  /// How many of those days are known; zero for a brand-new user.
  final int missedDays;

  /// 0–100, or null when there is nothing to count yet.
  int? get weekPercent =>
      weekPossible == 0 ? null : (weekPrayed * 100 / weekPossible).round();

  /// The prayers missed most (all of them on a tie); empty when nothing
  /// was missed.
  List<Prayer> get mostMissed {
    final most = missed.values.fold(0, math.max);
    if (most == 0) return const [];
    return [
      for (final p in trackedPrayers)
        if (missed[p] == most) p,
    ];
  }

  @override
  List<Object?> get props => [
    streak,
    weekPrayed,
    weekPossible,
    missed,
    missedDays,
  ];
}
