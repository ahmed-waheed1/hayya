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

/// [LocationService] that answers [locate] from a queue of results
/// (repeating the last one) and records what it was asked.
class FakeLocationService implements LocationService {
  FakeLocationService({this.lastKnown, List<LocationResult>? results})
    : _results = Queue.of(results ?? [LocationFound(cairo)]);

  @override
  UserLocation? lastKnown;

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
    permissionRequests.add(requestPermission);
    await gate?.future;
    final result = _results.length > 1
        ? _results.removeFirst()
        : _results.first;
    if (result case LocationFound(:final location)) {
      lastKnown = location;
      _changes.add(location);
    }
    return result;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}
