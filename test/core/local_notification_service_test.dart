import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/local_notification_service.dart';
import 'package:hayya/core/services/notification_service.dart';

/// What the plugin sends to Android, checked without a device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' || 'canScheduleExactNotifications' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  const labels = {
    NotificationSound.adhan: (name: 'Adhan', description: 'adhan'),
    NotificationSound.reminder: (name: 'Reminders', description: 'reminder'),
  };
  final at = DateTime.now().add(const Duration(hours: 1));

  Future<void> schedule(NotificationSound sound) =>
      LocalNotificationService().replacePending([
        ScheduledNotification(
          id: 1,
          at: at,
          title: 't',
          body: 'b',
          sound: sound,
        ),
      ], channels: labels);

  Map<Object?, Object?> argsOf(String method, [String? channelId]) =>
      calls
              .where((c) => c.method == method)
              .map((c) => c.arguments as Map)
              .firstWhere(
                (a) =>
                    channelId == null ||
                    a['id'] == channelId ||
                    (a['platformSpecifics'] as Map?)?['channelId'] == channelId,
              )
          as Map<Object?, Object?>;

  test('the old notification-stream adhan_v1 channel is deleted', () async {
    await LocalNotificationService().areNotificationsAllowed();
    expect(calls.where((c) => c.method == 'deleteNotificationChannel'), [
      isA<MethodCall>().having((c) => c.arguments, 'channel', 'adhan_v1'),
    ]);
    final initialize = calls.indexWhere((c) => c.method == 'initialize');
    final delete = calls.indexWhere(
      (c) => c.method == 'deleteNotificationChannel',
    );
    expect(initialize, lessThan(delete));
  });

  test('the adhan channel plays raw/adhan on the alarm stream', () async {
    await schedule(NotificationSound.adhan);

    final created = argsOf('createNotificationChannel', 'adhan_v2');
    expect(created['importance'], Importance.high.value);
    expect(created['sound'], 'adhan');
    expect(created['audioAttributesUsage'], AudioAttributesUsage.alarm.value);
  });

  test('the reminder channel stays on the notification stream', () async {
    await schedule(NotificationSound.reminder);

    final created = argsOf('createNotificationChannel', 'reminder_v1');
    expect(created['sound'], isNull);
    expect(
      created['audioAttributesUsage'],
      AudioAttributesUsage.notification.value,
    );
  });

  test('the scheduled adhan auto-cancels, without insistent sound or a '
      'full-screen intent', () async {
    await schedule(NotificationSound.adhan);

    final details =
        argsOf('zonedSchedule', 'adhan_v2')['platformSpecifics'] as Map;
    expect(details['channelId'], 'adhan_v2');
    expect(details['audioAttributesUsage'], AudioAttributesUsage.alarm.value);
    expect(details['autoCancel'], isTrue);
    expect(details['fullScreenIntent'], isFalse);
    expect(details['additionalFlags'], isNull);
  });
}
