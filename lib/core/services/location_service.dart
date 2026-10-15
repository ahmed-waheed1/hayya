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

/// Forward geocoding failed: offline, or (on iOS) nothing matched.
class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);

  final String? message;

  @override
  String toString() => 'PlaceSearchException: $message';
}

/// Where the user is: the device's location, with the last fix cached on
/// disk so the app can open instantly and work offline, or a city the
/// user chose by hand.
abstract interface class LocationService {
  /// The chosen city while [isManual], otherwise the most recent device
  /// fix from any session.
  UserLocation? get lastKnown;

  /// True while a city the user picked replaces the device's location.
  bool get isManual;

  /// Emits each location that becomes [lastKnown]: a new fix, or a city
  /// the user picked.
  Stream<UserLocation> get changes;

  /// The current location. While [isManual] that is the chosen city,
  /// straight away; otherwise the device's, as [locateDevice].
  ///
  /// With [requestPermission] false, a missing permission fails straight
  /// away instead of showing the system prompt.
  Future<LocationResult> locate({bool requestPermission = true});

  /// Finds the device's location and caches it, even while [isManual].
  /// Success switches back from the chosen city to the device's location;
  /// failure keeps the chosen city.
  Future<LocationResult> locateDevice({bool requestPermission = true});

  /// Places matching [query], at most a handful, named in every language
  /// the app has. Empty when nothing matches.
  ///
  /// Throws [PlaceSearchException] when the lookup fails.
  Future<List<UserLocation>> searchPlaces(String query);

  /// Uses [place] instead of the device's location until [locateDevice]
  /// succeeds.
  Future<void> useManualLocation(UserLocation place);

  /// Opens this app's page in the system settings.
  Future<void> openAppSettings();

  /// Opens the system's location (GPS) settings.
  Future<void> openLocationSettings();
}
