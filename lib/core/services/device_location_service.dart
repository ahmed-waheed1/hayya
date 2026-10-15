import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';
import 'user_location.dart';

/// [LocationService] backed by geolocator, permission_handler and
/// geocoding.
class DeviceLocationService implements LocationService {
  DeviceLocationService(this._prefs, {Geocoding? geocoding})
    : _geocoding = geocoding ?? Geocoding();

  final SharedPreferences _prefs;
  final Geocoding _geocoding;
  final _changes = StreamController<UserLocation>.broadcast();

  /// The last device fix.
  static const _cacheKey = 'last_location';

  /// The city the user picked, while it replaces the device's location.
  static const _manualKey = 'manual_location';

  /// Search results shown at most.
  static const _maxResults = 5;

  /// Languages the place name is stored in, so switching language doesn't
  /// need the network.
  static const _nameLanguages = ['en', 'ar'];

  /// A new fix this close to the cached one keeps the cached place names
  /// when geocoding fails.
  static const _sameAreaMeters = 10000.0;

  /// Prayer times need a city-level fix, not a precise one.
  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.low,
    timeLimit: Duration(seconds: 15),
  );

  @override
  UserLocation? get lastKnown => _read(_manualKey) ?? _read(_cacheKey);

  @override
  bool get isManual => _read(_manualKey) != null;

  UserLocation? _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return UserLocation.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object catch (e) {
      // A cache written by an older build; a fresh fix will replace it.
      debugPrint('Ignoring unreadable stored location ($key): $e');
      return null;
    }
  }

  @override
  Stream<UserLocation> get changes => _changes.stream;

  @override
  Future<LocationResult> locate({bool requestPermission = true}) async {
    if (_read(_manualKey) case final manual?) return LocationFound(manual);
    return locateDevice(requestPermission: requestPermission);
  }

  @override
  Future<LocationResult> locateDevice({bool requestPermission = true}) async {
    final permission = await _ensurePermission(request: requestPermission);
    if (permission != null) return LocationFailed(permission);

    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationFailed(LocationFailure.serviceDisabled);
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    } on LocationServiceDisabledException {
      return const LocationFailed(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const LocationFailed(LocationFailure.permissionDenied);
    }
    if (position == null) {
      return const LocationFailed(LocationFailure.unavailable);
    }

    final coordinates = GeoCoordinates(position.latitude, position.longitude);
    final place = await _describe(coordinates);
    // Offline, the cached fix's names are kept if we haven't moved far.
    final near = place == null ? _cachedNear(coordinates) : null;
    final location = UserLocation(
      coordinates: coordinates,
      updatedAt: DateTime.now(),
      placeNames: place?.names ?? near?.placeNames ?? const {},
      countryCode: place?.countryCode ?? near?.countryCode,
    );
    await _prefs.setString(_cacheKey, jsonEncode(location.toJson()));
    await _prefs.remove(_manualKey);
    _changes.add(location);
    return LocationFound(location);
  }

  @override
  Future<List<UserLocation>> searchPlaces(String query) async {
    final List<Location> found;
    try {
      found = await _geocoding.locationFromAddress(query.trim());
    } on PlatformException catch (e) {
      throw PlaceSearchException(e.message);
    }
    final now = DateTime.now();
    final places = await Future.wait([
      for (final hit in found.take(_maxResults))
        _describe(GeoCoordinates(hit.latitude, hit.longitude)).then(
          (place) => place == null
              ? null
              : UserLocation(
                  coordinates: GeoCoordinates(hit.latitude, hit.longitude),
                  updatedAt: now,
                  placeNames: place.names,
                  countryCode: place.countryCode,
                ),
        ),
    ]);
    // A city and its centre often come back as separate hits; namesakes
    // far apart (Alexandria, Egypt and Alexandria, Virginia) both stay.
    final results = <UserLocation>[];
    for (final place in places.nonNulls) {
      final duplicate = results.any(
        (r) =>
            mapEquals(r.placeNames, place.placeNames) &&
            _distance(r.coordinates, place.coordinates) <= _sameAreaMeters,
      );
      if (!duplicate) results.add(place);
    }
    return results;
  }

  @override
  Future<void> useManualLocation(UserLocation place) async {
    await _prefs.setString(_manualKey, jsonEncode(place.toJson()));
    _changes.add(place);
  }

  /// Null when granted, otherwise why not.
  Future<LocationFailure?> _ensurePermission({required bool request}) async {
    const permission = ph.Permission.locationWhenInUse;
    var status = await permission.status;
    if (_granted(status)) return null;
    if (request && !_blocked(status)) status = await permission.request();
    if (_granted(status)) return null;
    return _blocked(status)
        ? LocationFailure.permissionDeniedForever
        : LocationFailure.permissionDenied;
  }

  static bool _granted(ph.PermissionStatus s) => s.isGranted || s.isLimited;

  static bool _blocked(ph.PermissionStatus s) =>
      s.isPermanentlyDenied || s.isRestricted;

  /// City and country in each of [_nameLanguages], and the country code.
  /// Geocoding needs the network; null when it failed in every language.
  Future<({Map<String, PlaceName> names, String? countryCode})?> _describe(
    GeoCoordinates at,
  ) async {
    final names = <String, PlaceName>{};
    String? countryCode;
    for (final language in _nameLanguages) {
      try {
        final marks = await _geocoding.placemarkFromCoordinates(
          at.latitude,
          at.longitude,
          locale: Locale(language),
        );
        final name = marks.map(_toPlaceName).nonNulls.firstOrNull;
        if (name != null) names[language] = name;
        countryCode ??= marks
            .map((m) => m.isoCountryCode)
            .where((c) => c != null && c.trim().isNotEmpty)
            .firstOrNull;
      } on PlatformException catch (e) {
        // Offline, or no place at these coordinates (open sea).
        debugPrint('Geocoding ($language) failed: ${e.message}');
      }
    }
    if (names.isEmpty) return null;
    return (names: names, countryCode: countryCode);
  }

  /// The cached fix, if it is within [_sameAreaMeters] of [at].
  UserLocation? _cachedNear(GeoCoordinates at) {
    final cached = _read(_cacheKey);
    if (cached == null) return null;
    return _distance(cached.coordinates, at) <= _sameAreaMeters ? cached : null;
  }

  static double _distance(GeoCoordinates a, GeoCoordinates b) =>
      Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );

  static PlaceName? _toPlaceName(Placemark mark) {
    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s;
    final city =
        clean(mark.locality) ??
        clean(mark.subAdministrativeArea) ??
        clean(mark.administrativeArea);
    final country = clean(mark.country);
    if (city == null && country == null) return null;
    return PlaceName(city: city, country: country);
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
