/// Work the system runs while the app is closed: for now, keeping the adhan
/// schedule topped up (see docs/background-reschedule.md).
abstract interface class BackgroundTasks {
  /// Registers the daily adhan reschedule with the system. Called on every
  /// launch and after onboarding; an existing registration is updated in
  /// place, never duplicated.
  Future<void> ensureRegistered();

  /// Debug aid: asks the system to run the reschedule once, right away,
  /// the same way it runs the daily one.
  Future<void> runRescheduleNow();
}
