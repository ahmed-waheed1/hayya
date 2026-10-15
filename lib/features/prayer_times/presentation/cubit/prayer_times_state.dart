import 'package:equatable/equatable.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../domain/entities/hijri_date.dart';
import '../../domain/entities/prayer_schedule.dart';

sealed class PrayerTimesState extends Equatable {
  const PrayerTimesState();

  @override
  List<Object?> get props => [];
}

/// First launch, before any location is known.
final class PrayerTimesLoading extends PrayerTimesState {
  const PrayerTimesLoading();
}

/// Times for [location], recalculated every second.
final class PrayerTimesReady extends PrayerTimesState {
  const PrayerTimesReady({
    required this.location,
    required this.schedule,
    required this.hijriDate,
    this.locating = false,
  });

  final UserLocation location;
  final PrayerSchedule schedule;
  final HijriDate hijriDate;

  /// A fresh location is being looked up; [location] may be stale.
  final bool locating;

  @override
  List<Object?> get props => [location, schedule, hijriDate, locating];
}

/// No usable location. [lastKnown], when present, can be used instead.
final class PrayerTimesLocationError extends PrayerTimesState {
  const PrayerTimesLocationError(this.reason, {this.lastKnown});

  final LocationFailure reason;
  final UserLocation? lastKnown;

  @override
  List<Object?> get props => [reason, lastKnown];
}
