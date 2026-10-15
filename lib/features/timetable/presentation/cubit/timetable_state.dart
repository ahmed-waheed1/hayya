import 'package:equatable/equatable.dart';

import '../../../../core/services/user_location.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../domain/entities/timetable_month.dart';

sealed class TimetableState extends Equatable {
  const TimetableState();

  @override
  List<Object?> get props => [];
}

/// No location has been found yet, so there is nothing to calculate.
final class TimetableNoLocation extends TimetableState {
  const TimetableNoLocation();
}

final class TimetableReady extends TimetableState {
  const TimetableReady({
    required this.location,
    required this.settings,
    required this.timetable,
    required this.today,
  });

  final UserLocation location;
  final PrayerCalculationSettings settings;
  final TimetableMonth timetable;

  /// Local midnight of the current day, highlighted when [timetable]
  /// contains it.
  final DateTime today;

  CalendarMonth get month => timetable.month;

  /// Today's row in [timetable], or null in another month.
  int? get todayIndex => timetable.indexOf(today);

  @override
  List<Object?> get props => [location, settings, timetable, today];
}
