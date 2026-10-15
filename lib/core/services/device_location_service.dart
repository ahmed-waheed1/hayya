import 'dart:async';
import 'dart:convert';

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

  static const _cacheKey = 'last_location';

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
  UserLocation? get lastKnown {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return UserLocation.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object catch (e) {
      // A cache written by an older build; a fresh fix will replace it.
      debugPrint('Ignoring unreadable cached location: $e');
      return null;
    }
  }

  @override
  Stream<UserLocation> get changes => _changes.stream;

  @override
  Future<LocationResult> locate({bool requestPermission = true}) async {
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

    final location = UserLocation(
      coordinates: GeoCoordinates(position.latitude, position.longitude),
      updatedAt: DateTime.now(),
      placeNames: await _placeNames(position),
    );
    await _prefs.setString(_cacheKey, jsonEncode(location.toJson()));
    _changes.add(location);
    return LocationFound(location);
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

  /// City and country in each of [_nameLanguages]. Geocoding needs the
  /// network; offline, the cached names are kept if we haven't moved far.
  Future<Map<String, PlaceName>> _placeNames(Position position) async {
    final names = <String, PlaceName>{};
    for (final language in _nameLanguages) {
      try {
        final marks = await _geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
          locale: Locale(language),
        );
        final name = marks.map(_toPlaceName).nonNulls.firstOrNull;
        if (name != null) names[language] = name;
      } on PlatformException catch (e) {
        // Offline, or no place at these coordinates (open sea).
        debugPrint('Geocoding ($language) failed: ${e.message}');
      }
    }
    if (names.isNotEmpty) return names;

    final cached = lastKnown;
    if (cached == null) return names;
    final moved = Geolocator.distanceBetween(
      cached.coordinates.latitude,
      cached.coordinates.longitude,
      position.latitude,
      position.longitude,
    );
    return moved <= _sameAreaMeters ? cached.placeNames : names;
  }

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
