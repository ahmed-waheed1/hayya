import 'dart:async';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/services/background_tasks.dart';
import '../../../core/services/location_service.dart';
import '../../notifications/domain/repositories/adhan_preferences_repository.dart';

/// Whether onboarding is shown at launch: only the first time.
///
/// It counts as done once finished or skipped, and also for anyone who
/// used the app before onboarding existed (a location is known, or the
/// notification permission was already asked for), so an update doesn't
/// show it to them.
class OnboardingStatus {
  const OnboardingStatus({
    required this._preferences,
    required this._locationService,
    required this._adhanPreferences,
    required this._backgroundTasks,
  });

  final AppPreferences _preferences;
  final LocationService _locationService;
  final AdhanPreferencesRepository _adhanPreferences;
  final BackgroundTasks _backgroundTasks;

  bool get shouldShow =>
      !_preferences.onboardingDone &&
      _locationService.lastKnown == null &&
      !_adhanPreferences.permissionPrompted;

  /// Marks onboarding done and registers the background reschedule again,
  /// now that there is a location and a notification choice to keep up.
  /// Home doesn't wait for the registration.
  Future<void> complete() async {
    await _preferences.setOnboardingDone();
    unawaited(_backgroundTasks.ensureRegistered());
  }
}
