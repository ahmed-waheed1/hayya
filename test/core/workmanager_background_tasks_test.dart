import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/services/workmanager_background_tasks.dart';
import 'package:workmanager/workmanager.dart';

/// [Workmanager] that records registrations instead of reaching a platform.
class _FakeWorkmanager implements Workmanager {
  final initialized = <Function>[];
  final periodic =
      <
        ({
          String uniqueName,
          String taskName,
          Duration? frequency,
          Duration? initialDelay,
          ExistingPeriodicWorkPolicy? policy,
          bool foreground,
        })
      >[];
  final oneOff =
      <
        ({
          String uniqueName,
          String taskName,
          ExistingWorkPolicy? policy,
          bool foreground,
          bool expedited,
        })
      >[];
  Object? failWith;

  @override
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async {
    if (failWith case final error?) throw error;
    initialized.add(callbackDispatcher);
  }

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async => periodic.add((
    uniqueName: uniqueName,
    taskName: taskName,
    frequency: frequency,
    initialDelay: initialDelay,
    policy: existingWorkPolicy,
    foreground: foregroundServiceConfig != null,
  ));

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    ForegroundServiceConfig? foregroundServiceConfig,
    bool expedited = false,
  }) async => oneOff.add((
    uniqueName: uniqueName,
    taskName: taskName,
    policy: existingWorkPolicy,
    foreground: foregroundServiceConfig != null,
    expedited: expedited,
  ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeWorkmanager workmanager;
  late WorkmanagerBackgroundTasks tasks;

  setUp(() {
    workmanager = _FakeWorkmanager();
    tasks = WorkmanagerBackgroundTasks(workmanager: workmanager);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('registers one daily task, updated in place on every call', () async {
    await tasks.ensureRegistered();
    await tasks.ensureRegistered();

    expect(workmanager.initialized, [
      backgroundTaskDispatcher,
      backgroundTaskDispatcher,
    ]);
    expect(workmanager.periodic, hasLength(2));
    for (final r in workmanager.periodic) {
      expect(r.uniqueName, WorkmanagerBackgroundTasks.rescheduleTask);
      expect(r.taskName, WorkmanagerBackgroundTasks.rescheduleTask);
      expect(r.frequency, const Duration(days: 1));
      // Android starts the period at registration; no delay on top.
      expect(r.initialDelay, isNull);
      // Same unique name and "update": one task, its schedule kept.
      expect(r.policy, ExistingPeriodicWorkPolicy.update);
    }
  });

  test('iOS: asks for the earliest next run instead', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tasks.ensureRegistered();
    expect(
      workmanager.periodic.single.initialDelay,
      WorkmanagerBackgroundTasks.iosEarliestBegin,
    );
  });

  test('a platform failure never reaches the app', () async {
    workmanager.failWith = Exception('no plugin');
    await expectLater(tasks.ensureRegistered(), completes);
    expect(workmanager.periodic, isEmpty);
  });

  test('running it now is a separate one-off task', () async {
    await tasks.runRescheduleNow();
    final run = workmanager.oneOff.single;
    expect(run.uniqueName, WorkmanagerBackgroundTasks.runNowName);
    expect(run.uniqueName, isNot(WorkmanagerBackgroundTasks.rescheduleTask));
    expect(run.taskName, WorkmanagerBackgroundTasks.rescheduleTask);
    expect(run.policy, ExistingWorkPolicy.replace);
  });

  // AndroidManifest.xml removes workmanager's FOREGROUND_SERVICE
  // permissions; a foreground or expedited worker would need them back.
  test('never runs as a foreground service', () async {
    await tasks.ensureRegistered();
    await tasks.runRescheduleNow();
    expect(workmanager.periodic.single.foreground, isFalse);
    expect(workmanager.oneOff.single.foreground, isFalse);
    expect(workmanager.oneOff.single.expedited, isFalse);
  });
}
