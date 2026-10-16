import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';
import '../../../prayer_times/domain/repositories/prayer_settings_repository.dart';
import '../../../prayer_times/domain/usecases/get_prayer_schedule.dart';
import '../../domain/onboarding_status.dart';
import 'onboarding_state.dart';

/// First launch: welcome (with the language), then the location and
/// notification permissions, each explained before the system prompt.
///
/// A refused permission never blocks: the slide explains what that means
/// and how to turn it on later, and for location offers a city instead.
/// Skipping finishes at once. Finishing or skipping is saved, so
/// onboarding never shows again.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required this._status,
    required this._locationService,
    required this._settingsRepository,
    required this._getSchedule,
    required this._requestNotifications,
    this._clock = DateTime.now,
  }) : super(const OnboardingState()) {
    // A fix, or a city chosen in the sheet.
    _changes = _locationService.changes.listen(_found);
  }

  final OnboardingStatus _status;
  final LocationService _locationService;
  final PrayerSettingsRepository _settingsRepository;
  final GetPrayerSchedule _getSchedule;

  /// Asks for the notification permission; true when allowed.
  final Future<bool> Function() _requestNotifications;
  final DateTime Function() _clock;

  late final StreamSubscription<UserLocation> _changes;

  void next() => switch (state.page) {
    OnboardingPage.welcome => emit(
      state.copyWith(page: OnboardingPage.location),
    ),
    OnboardingPage.location => emit(
      state.copyWith(page: OnboardingPage.notifications),
    ),
    OnboardingPage.notifications => finish(),
  };

  void back() => switch (state.page) {
    OnboardingPage.welcome => null,
    OnboardingPage.location => emit(
      state.copyWith(page: OnboardingPage.welcome),
    ),
    OnboardingPage.notifications => emit(
      state.copyWith(page: OnboardingPage.location),
    ),
  };

  /// "Allow location": the system prompt, then a fix.
  Future<void> allowLocation() => _locate(requestPermission: true);

  /// Back from the system settings: try again without prompting.
  Future<void> recheckLocation() async {
    if (state.page == OnboardingPage.location &&
        state.locationFailure != null &&
        !state.locating) {
      await _locate(requestPermission: false);
    }
  }

  Future<void> openSettingsFor(LocationFailure reason) =>
      reason == LocationFailure.serviceDisabled
      ? _locationService.openLocationSettings()
      : _locationService.openAppSettings();

  Future<void> _locate({required bool requestPermission}) async {
    if (state.locating) return;
    emit(state.copyWith(locating: true, locationFailure: () => null));
    final result = await _locationService.locate(
      requestPermission: requestPermission,
    );
    if (isClosed) return;
    switch (result) {
      // The service reports it as a change too; [_found] is idempotent.
      case LocationFound(:final location):
        _found(location);
      case LocationFailed(:final reason):
        emit(state.copyWith(locating: false, locationFailure: () => reason));
    }
  }

  void _found(UserLocation location) {
    if (isClosed) return;
    final schedule = _getSchedule(
      now: _clock(),
      coordinates: location.coordinates,
      settings: _settingsRepository.settings,
    );
    emit(
      state.copyWith(
        location: location,
        nextPrayer: schedule.next,
        locating: false,
        locationFailure: () => null,
        // Found from the location slide: on to notifications.
        page: state.page == OnboardingPage.location
            ? OnboardingPage.notifications
            : null,
      ),
    );
  }

  /// "Allow notifications": finishes when allowed; when refused, the
  /// slide explains and its button continues.
  Future<void> allowNotifications() async {
    if (state.requestingNotifications) return;
    emit(state.copyWith(requestingNotifications: true));
    final allowed = await _requestNotifications();
    if (isClosed) return;
    emit(
      state.copyWith(
        requestingNotifications: false,
        notificationsDenied: !allowed,
      ),
    );
    if (allowed) await finish();
  }

  /// Skip, or the last step done: saved, then Home.
  Future<void> finish() async {
    if (state.done) return;
    await _status.complete();
    if (!isClosed) emit(state.copyWith(done: true));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
