import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer.dart';

enum NotificationKind { adhan, reminder }

/// A notification the plan wants at [at]: the adhan itself, or a reminder
/// ahead of [prayerTime].
class PlannedNotification extends Equatable {
  const PlannedNotification({
    required this.prayer,
    required this.kind,
    required this.prayerTime,
    required this.at,
  });

  final Prayer prayer;
  final NotificationKind kind;
  final DateTime prayerTime;
  final DateTime at;

  /// The same for one prayer on one day however often it is planned:
  /// day number × 20 + prayer × 2 + kind. Fits a 32-bit Android id.
  int get id {
    final day = DateTime.utc(
      prayerTime.year,
      prayerTime.month,
      prayerTime.day,
    ).difference(DateTime.utc(1970)).inDays;
    return (day % 100000) * 20 + prayer.index * 2 + kind.index;
  }

  @override
  List<Object?> get props => [prayer, kind, prayerTime, at];
}
