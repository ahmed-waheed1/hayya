import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer.dart';
import 'calendar_day.dart';

/// The five prayers the tracker counts, in order. Sunrise isn't one.
const trackedPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Everything the tracker keeps on the device.
class TrackerData extends Equatable {
  TrackerData({
    required DateTime since,
    Map<DateTime, Set<Prayer>> days = const {},
    this.qadaOwed = const {},
    this.qadaMadeUp = 0,
  }) : since = since.dateOnly,
       days = Map.unmodifiable({
         for (final MapEntry(:key, :value) in days.entries)
           if (value.isNotEmpty) key.dateOnly: Set<Prayer>.unmodifiable(value),
       });

  /// The day tracking began (the first launch with the tracker). Days
  /// before it with nothing recorded are unknown, never missed.
  final DateTime since;

  /// The prayers marked as prayed, keyed by local midnight. Days with
  /// nothing prayed are left out.
  final Map<DateTime, Set<Prayer>> days;

  /// Missed prayers the user still owes, per prayer. Zero entries may be
  /// left out.
  final Map<Prayer, int> qadaOwed;

  /// Made-up prayers logged so far, across all prayers.
  final int qadaMadeUp;

  Set<Prayer> prayedOn(DateTime day) => days[day.dateOnly] ?? const {};

  /// Whether [day] counts in the stats: on or after [since], or a day
  /// before it that the user filled in.
  bool isKnown(DateTime day) =>
      !day.dateOnly.isBefore(since) || days.containsKey(day.dateOnly);

  int owed(Prayer prayer) => qadaOwed[prayer] ?? 0;

  int get totalOwed => qadaOwed.values.fold(0, (sum, n) => sum + n);

  /// Nothing has been marked yet.
  bool get hasNoPrayers => days.isEmpty;

  @override
  List<Object?> get props => [since, days, qadaOwed, qadaMadeUp];
}
