import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

/// [NotificationService] backed by flutter_local_notifications.
///
/// Times are scheduled as UTC instants, so the time zone database isn't
/// needed and a time zone change can't shift an adhan.
///
/// After a reboot or app update, the plugin's boot receiver (see
/// AndroidManifest.xml) restores the pending alarms on Android; iOS keeps
/// them itself.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialized;

  /// The plugin's code when an exact alarm is refused (Android 12+).
  static const _exactAlarmsNotPermitted = 'exact_alarms_not_permitted';

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> _ensureInitialized() => _initialized ??= _initialize();

  Future<void> _initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked for when it makes sense, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    // Deleting a channel that doesn't exist is a no-op.
    for (final id in NotificationSound.retiredChannelIds) {
      await _android?.deleteNotificationChannel(channelId: id);
    }
  }

  @override
  int get maxPending => _isIOS ? 64 : 500;

  /// A week on Android, topped up daily in the background. On iOS
  /// [maxPending] cuts the plan short: even one notification a day fills
  /// the 64 slots.
  @override
  int get planDays => _isIOS ? maxPending : 7;

  @override
  Future<bool> areNotificationsAllowed() async {
    await _ensureInitialized();
    if (_isIOS) return (await _ios?.checkPermissions())?.isEnabled ?? false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    await _ensureInitialized();
    if (_isIOS) {
      return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    // Below Android 13 there is no prompt; this reports the current state.
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> canScheduleExact() async {
    await _ensureInitialized();
    if (_isIOS) return true;
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  @override
  Future<void> requestExactAlarms() async {
    await _ensureInitialized();
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> openNotificationSettings() async {
    await _ensureInitialized();
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<void> replacePending(
    List<ScheduledNotification> notifications, {
    required Map<NotificationSound, ChannelLabel> channels,
  }) async {
    await _ensureInitialized();
    // Creating an existing channel again only updates its name and
    // description, which keeps them in the app's language.
    for (final MapEntry(key: sound, value: label) in channels.entries) {
      await _android?.createNotificationChannel(_channel(sound, label));
    }

    await _plugin.cancelAllPendingNotifications();
    var mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final n in notifications) {
      try {
        await _schedule(n, channels[n.sound]!, mode);
      } on PlatformException catch (e) {
        // Exact alarms were revoked while scheduling.
        if (e.code != _exactAlarmsNotPermitted) rethrow;
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
        await _schedule(n, channels[n.sound]!, mode);
      }
    }
  }

  Future<void> _schedule(
    ScheduledNotification n,
    ChannelLabel label,
    AndroidScheduleMode mode,
  ) => _plugin.zonedSchedule(
    id: n.id,
    scheduledDate: tz.TZDateTime.from(n.at, tz.UTC),
    title: n.title,
    body: n.body,
    androidScheduleMode: mode,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        n.sound.channelId,
        label.name,
        channelDescription: label.description,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        sound: _androidSound(n.sound),
        // Used below Android 8; from 8 on the channel decides.
        audioAttributesUsage: _usage(n.sound),
        // Tapping opens the app and removes the notification; removing it
        // (tap, swipe or "Clear all") stops the sound. Kept explicit
        // because the adhan must stay easy to silence.
        autoCancel: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        sound: _iosSound(n.sound),
      ),
    ),
  );

  static AndroidNotificationChannel _channel(
    NotificationSound sound,
    ChannelLabel label,
  ) => AndroidNotificationChannel(
    sound.channelId,
    label.name,
    description: label.description,
    importance: Importance.high,
    sound: _androidSound(sound),
    audioAttributesUsage: _usage(sound),
  );

  static AudioAttributesUsage _usage(NotificationSound sound) =>
      sound.alarmStream
      ? AudioAttributesUsage.alarm
      : AudioAttributesUsage.notification;

  static RawResourceAndroidNotificationSound? _androidSound(
    NotificationSound sound,
  ) => switch (sound.fileName) {
    final name? => RawResourceAndroidNotificationSound(name),
    null => null,
  };

  /// iOS plays only files in the app bundle, up to 30 seconds; longer or
  /// missing files fall back to the default sound.
  static String? _iosSound(NotificationSound sound) => switch (sound.fileName) {
    final name? => '$name.caf',
    null => null,
  };
}
