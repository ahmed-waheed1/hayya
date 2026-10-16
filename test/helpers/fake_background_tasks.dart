import 'package:hayya/core/services/background_tasks.dart';

/// [BackgroundTasks] that counts what it was asked to do.
class FakeBackgroundTasks implements BackgroundTasks {
  var registrations = 0;
  var runs = 0;

  @override
  Future<void> ensureRegistered() async => registrations++;

  @override
  Future<void> runRescheduleNow() async => runs++;
}
