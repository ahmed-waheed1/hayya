import 'package:equatable/equatable.dart';

/// A sound a notification plays.
///
/// Android fixes which sound a channel plays when the channel is first
/// created, so each sound has its own channel. New audio under the same
/// [fileName] plays on existing channels; changing [fileName] or other
/// channel settings needs a new [channelId] (e.g. bump `_v1` to `_v2`);
/// add the old id to [retiredChannelIds] so it is deleted.
enum NotificationSound {
  /// The full adhan: `res/raw/adhan.mp3` on Android, `adhan.caf` in the
  /// iOS app bundle. Plays on the alarm stream, so a low notification
  /// volume or silent mode doesn't mute it.
  adhan(channelId: 'adhan_v2', fileName: 'adhan', alarmStream: true),

  /// The same adhan on the notification stream, for users who want silent
  /// mode to silence it too (Settings → Adhan volume).
  adhanNotificationVolume(
    channelId: 'adhan_notification_v1',
    fileName: 'adhan',
  ),

  /// The pre-adhan reminder, with the system's default tone on the normal
  /// notification stream.
  reminder(channelId: 'reminder_v1');

  const NotificationSound({
    required this.channelId,
    this.fileName,
    this.alarmStream = false,
  });

  final String channelId;

  /// Base name of the sound file, without extension. Null plays the
  /// system default.
  final String? fileName;

  /// Android: play at alarm volume (`USAGE_ALARM`) instead of notification
  /// volume. Fixed when the channel is created.
  final bool alarmStream;

  /// Channels from earlier builds, deleted at startup so they don't linger
  /// in the system settings. `adhan_v1` played on the notification stream.
  static const retiredChannelIds = ['adhan_v1'];
}

/// One notification to show at [at].
class ScheduledNotification extends Equatable {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.sound,
  });

  /// Stable for the same event, so rescheduling replaces rather than
  /// duplicates it.
  final int id;
  final DateTime at;
  final String title;
  final String body;
  final NotificationSound sound;

  @override
  List<Object?> get props => [id, at, title, body, sound];
}

/// A notification channel's user-visible name, shown in the system
/// settings.
typedef ChannelLabel = ({String name, String description});

/// Schedules local notifications and reports what the system allows.
abstract interface class NotificationService {
  /// How many notifications may be pending at once. iOS keeps only the
  /// 64 soonest and silently drops the rest.
  int get maxPending;

  /// How many days ahead the adhan is planned. Android tops the schedule
  /// up in the background every day, so a week is plenty. iOS can't count
  /// on background runs, so it plans as far ahead as [maxPending] allows.
  int get planDays;

  /// Whether the user lets the app post notifications at all.
  Future<bool> areNotificationsAllowed();

  /// Shows the system prompt (Android 13+, iOS) when it still can.
  /// Returns whether notifications are allowed afterwards.
  Future<bool> requestNotificationPermission();

  /// False on Android 12+ when "Alarms & reminders" is off. Notifications
  /// are then scheduled inexactly and may arrive minutes late.
  Future<bool> canScheduleExact();

  /// Opens the system page where exact alarms can be allowed.
  Future<void> requestExactAlarms();

  /// Opens this app's notification settings.
  Future<void> openNotificationSettings();

  /// Replaces every pending notification with [notifications]. Ones
  /// already shown stay in the notification shade.
  ///
  /// [channels] names each sound's channel in the app's language.
  Future<void> replacePending(
    List<ScheduledNotification> notifications, {
    required Map<NotificationSound, ChannelLabel> channels,
  });
}
