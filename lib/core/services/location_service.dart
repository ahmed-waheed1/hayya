import 'user_location.dart';

/// Why a fresh location couldn't be found.
enum LocationFailure {
  /// The user declined; asking again may still show the system prompt.
  permissionDenied,

  /// Declined for good (or restricted); only the system settings can
  /// change it.
  permissionDeniedForever,

  /// Location services (GPS) are switched off.
  serviceDisabled,

  /// Permission and services are fine, but no fix arrived in time.
  unavailable,
}

sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound(this.location);

  final UserLocation location;
}

final class LocationFailed extends LocationResult {
  const LocationFailed(this.reason);

  final LocationFailure reason;
}

/// The device's location, with the last fix cached on disk so the app can
/// open instantly and work offline.
abstract interface class LocationService {
  /// The most recent successful [locate] result, from any session.
  UserLocation? get lastKnown;

  /// Emits each location [locate] finds and caches.
  Stream<UserLocation> get changes;

  /// Finds the current location and caches it.
  ///
  /// With [requestPermission] false, a missing permission fails straight
  /// away instead of showing the system prompt.
  Future<LocationResult> locate({bool requestPermission = true});

  /// Opens this app's page in the system settings.
  Future<void> openAppSettings();

  /// Opens the system's location (GPS) settings.
  Future<void> openLocationSettings();
}
