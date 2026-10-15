import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer.dart';

/// Which volume the adhan plays at (Android; iOS notification sounds
/// always follow the ring/silent switch).
enum AdhanVolume {
  /// Alarm volume: plays even in silent or vibrate mode.
  alarm,

  /// Notification volume: silent mode silences it.
  notification,
}

/// Which prayers sound the adhan, how loud, and the optional reminder
/// before it.
class AdhanPreferences extends Equatable {
  const AdhanPreferences({
    this.enabled = defaultEnabled,
    this.reminderOn = false,
    this.reminderMinutes = defaultReminderMinutes,
    this.volume = AdhanVolume.alarm,
  });

  /// Every prayer with an adhan (not Sunrise).
  static const defaultEnabled = {
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  };

  /// The reminder lead times offered in Settings.
  static const reminderOptions = [5, 10, 15, 30];
  static const defaultReminderMinutes = 10;

  /// Prayers whose adhan notification is on. Never contains Sunrise.
  final Set<Prayer> enabled;

  /// Off by default. [reminderMinutes] is kept while off, so turning it
  /// back on restores the last choice.
  final bool reminderOn;
  final int reminderMinutes;

  final AdhanVolume volume;

  bool isEnabled(Prayer prayer) =>
      prayer.isObligatory && enabled.contains(prayer);

  /// The reminder's lead time, or null when it is off.
  Duration? get reminder =>
      reminderOn ? Duration(minutes: reminderMinutes) : null;

  AdhanPreferences withPrayer(Prayer prayer, {required bool on}) => copyWith(
    enabled: on ? {...enabled, prayer} : ({...enabled}..remove(prayer)),
  );

  AdhanPreferences copyWith({
    Set<Prayer>? enabled,
    bool? reminderOn,
    int? reminderMinutes,
    AdhanVolume? volume,
  }) => AdhanPreferences(
    enabled: enabled ?? this.enabled,
    reminderOn: reminderOn ?? this.reminderOn,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    volume: volume ?? this.volume,
  );

  @override
  List<Object?> get props => [enabled, reminderOn, reminderMinutes, volume];
}
