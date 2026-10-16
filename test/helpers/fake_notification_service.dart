import 'package:hayya/core/services/notification_service.dart';
import 'package:hayya/features/notifications/domain/usecases/plan_adhan_notifications.dart';

/// [NotificationService] that records what would be pending.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.maxPending = 64,
    this.planDays = PlanAdhanNotifications.days,
    this.allowed = true,
    this.exact = true,
    this.grantOnRequest = true,
  });

  @override
  final int maxPending;

  @override
  final int planDays;

  bool allowed;
  bool exact;
  bool grantOnRequest;

  /// What is pending now, and how often it was replaced.
  List<ScheduledNotification> pending = [];
  Map<NotificationSound, ChannelLabel> channels = {};

  /// Every [replacePending] call's notifications and channels, in order.
  final calls =
      <
        ({
          List<ScheduledNotification> notifications,
          Map<NotificationSound, ChannelLabel> channels,
        })
      >[];
  var replaceCalls = 0;
  var permissionRequests = 0;
  var exactRequests = 0;
  var settingsOpened = 0;

  /// Thrown by the next [replacePending], once.
  Object? failNext;

  @override
  Future<bool> areNotificationsAllowed() async => allowed;

  @override
  Future<bool> requestNotificationPermission() async {
    permissionRequests++;
    if (grantOnRequest) allowed = true;
    return allowed;
  }

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<void> requestExactAlarms() async => exactRequests++;

  @override
  Future<void> openNotificationSettings() async => settingsOpened++;

  @override
  Future<void> replacePending(
    List<ScheduledNotification> notifications, {
    required Map<NotificationSound, ChannelLabel> channels,
  }) async {
    replaceCalls++;
    calls.add((notifications: List.of(notifications), channels: channels));
    if (failNext case final error?) {
      failNext = null;
      throw error;
    }
    pending = List.of(notifications);
    this.channels = channels;
  }
}
