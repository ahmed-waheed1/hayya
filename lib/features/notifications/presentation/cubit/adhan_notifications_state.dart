import 'package:equatable/equatable.dart';

import '../../domain/entities/adhan_preferences.dart';

class AdhanNotificationsState extends Equatable {
  const AdhanNotificationsState({
    required this.preferences,
    this.notificationsAllowed = true,
    this.exactAlarmsAllowed = true,
  });

  final AdhanPreferences preferences;

  /// False when the user blocked notifications; nothing will show.
  final bool notificationsAllowed;

  /// False on Android 12+ without "Alarms & reminders"; the adhan may
  /// then arrive a few minutes late.
  final bool exactAlarmsAllowed;

  AdhanNotificationsState copyWith({
    AdhanPreferences? preferences,
    bool? notificationsAllowed,
    bool? exactAlarmsAllowed,
  }) => AdhanNotificationsState(
    preferences: preferences ?? this.preferences,
    notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
    exactAlarmsAllowed: exactAlarmsAllowed ?? this.exactAlarmsAllowed,
  );

  @override
  List<Object?> get props => [
    preferences,
    notificationsAllowed,
    exactAlarmsAllowed,
  ];
}
