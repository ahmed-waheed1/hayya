import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/notifications/domain/adhan_scheduler.dart';
import '../di/background_reschedule.dart';
import '../di/injection.dart';
import 'background_tasks.dart';

/// Where the system starts Dart for a background task, usually in a fresh
/// isolate with nothing of the app's set up.
///
/// Must stay a top-level function with this name and `vm:entry-point`:
/// the system finds it again by name after an app update.
@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  Workmanager().executeTask((task, _) async {
    // Plugins implemented in Dart (shared_preferences among them) aren't
    // registered in a background isolate otherwise.
    DartPluginRegistrant.ensureInitialized();
    if (task != WorkmanagerBackgroundTasks.rescheduleTask) {
      debugPrint('Unknown background task "$task"; ignoring it.');
      return true;
    }
    // iOS may run a one-off task on the open app's own engine; the app's
    // scheduler already has everything, and reloading translations here
    // would replace the app's.
    if (getIt.isRegistered<AdhanScheduler>()) {
      await getIt<AdhanScheduler>().reschedule(force: true);
      return true;
    }
    return rescheduleAdhanInBackground();
  });
}

/// [BackgroundTasks] backed by workmanager: Android's WorkManager, and
/// BGTaskScheduler on iOS.
///
/// WorkManager keeps the periodic task across reboots and app updates
/// (its database and boot receiver are part of the library); re-registering
/// on every launch also refreshes the stored entry point.
class WorkmanagerBackgroundTasks implements BackgroundTasks {
  WorkmanagerBackgroundTasks({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  /// The reschedule's unique name and task name on both platforms. On iOS
  /// it is also the BGTaskScheduler identifier, so it must match
  /// `BGTaskSchedulerPermittedIdentifiers` in Info.plist and AppDelegate.
  static const rescheduleTask = 'com.ahmedwaheed.hayya.adhanReschedule';

  /// The debug button's one-off run, kept apart from the periodic task so
  /// running it doesn't touch the daily schedule.
  static const runNowName = '$rescheduleTask.now';

  /// Android runs it about this often (its minimum is 15 minutes).
  static const frequency = Duration(days: 1);

  /// iOS ignores [frequency]: this is the earliest it may run again, and
  /// it usually runs later. AppDelegate.swift uses the same delay.
  static const iosEarliestBegin = Duration(hours: 12);

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> ensureRegistered() async {
    try {
      await _workmanager.initialize(backgroundTaskDispatcher);
      await _workmanager.registerPeriodicTask(
        rescheduleTask,
        rescheduleTask,
        frequency: frequency,
        initialDelay: _isIOS ? iosEarliestBegin : null,
        // Updates a registration in place, keeping its schedule, so
        // calling this on every launch never duplicates or postpones it.
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } on Object catch (e, stack) {
      // The app works without it; notifications then last until the
      // planned horizon, and the next launch tries again.
      debugPrint('Registering the background reschedule failed: $e\n$stack');
    }
  }

  @override
  Future<void> runRescheduleNow() async {
    await _workmanager.initialize(backgroundTaskDispatcher);
    await _workmanager.registerOneOffTask(
      runNowName,
      rescheduleTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
