import 'dart:async';
import 'dart:collection';

import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/user_location.dart';

final cairo = UserLocation(
  coordinates: const GeoCoordinates(30.0444, 31.2357),
  updatedAt: DateTime(2026, 10, 13, 12),
  placeNames: const {
    'en': PlaceName(city: 'Cairo', country: 'Egypt'),
    'ar': PlaceName(city: 'القاهرة', country: 'مصر'),
  },
);

final alexandria = UserLocation(
  coordinates: const GeoCoordinates(31.2001, 29.9187),
  updatedAt: DateTime(2026, 10, 13, 12),
  placeNames: const {
    'en': PlaceName(city: 'Alexandria', country: 'Egypt'),
    'ar': PlaceName(city: 'الإسكندرية', country: 'مصر'),
  },
  countryCode: 'EG',
);

/// [LocationService] that answers [locateDevice] from a queue of results
/// (repeating the last one) and records what it was asked.
///
/// [searchPlaces] answers from [places] by city-name prefix, or throws
/// [searchError] when set.
class FakeLocationService implements LocationService {
  FakeLocationService({
    UserLocation? lastKnown,
    List<LocationResult>? results,
    this.places = const [],
    this._manual,
  }) : _device = lastKnown,
       _results = Queue.of(results ?? [LocationFound(cairo)]);

  UserLocation? _device;
  UserLocation? _manual;

  @override
  UserLocation? get lastKnown => _manual ?? _device;

  /// Replaces the cached device fix without emitting a change.
  set lastKnown(UserLocation? location) => _device = location;

  @override
  bool get isManual => _manual != null;

  List<UserLocation> places;
  Object? searchError;
  final searches = <String>[];

  final Queue<LocationResult> _results;
  final _changes = StreamController<UserLocation>.broadcast(sync: true);

  @override
  Stream<UserLocation> get changes => _changes.stream;

  /// When set, [locate] waits for it before answering.
  Completer<void>? gate;

  final permissionRequests = <bool>[];
  var appSettingsOpened = 0;
  var locationSettingsOpened = 0;

  @override
  Future<LocationResult> locate({bool requestPermission = true}) async {
    if (_manual case final manual?) return LocationFound(manual);
    return locateDevice(requestPermission: requestPermission);
  }

  @override
  Future<LocationResult> locateDevice({bool requestPermission = true}) async {
    permissionRequests.add(requestPermission);
    await gate?.future;
    final result = _results.length > 1
        ? _results.removeFirst()
        : _results.first;
    if (result case LocationFound(:final location)) {
      _device = location;
      _manual = null;
      _changes.add(location);
    }
    return result;
  }

  @override
  Future<List<UserLocation>> searchPlaces(String query) async {
    searches.add(query);
    if (searchError case final error?) throw error;
    final q = query.trim().toLowerCase();
    return [
      for (final place in places)
        if (place.placeNames.values.any(
          (n) => n.city?.toLowerCase().startsWith(q) ?? false,
        ))
          place,
    ];
  }

  @override
  Future<void> useManualLocation(UserLocation place) async {
    _manual = place;
    _changes.add(place);
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}
