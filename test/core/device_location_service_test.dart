import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hayya/core/services/device_location_service.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/core/services/user_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_location_service.dart';

/// Answers forward lookups from [hits] and reverse lookups from [names],
/// keyed by "lat,lng" rounded to two places.
class _FakeGeocoding implements Geocoding {
  _FakeGeocoding({this.hits = const {}, this.names = const {}});

  final Map<String, List<Location>> hits;
  final Map<String, Map<String, Placemark>> names;
  Object? failForward;

  static String key(double lat, double lng) =>
      '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';

  @override
  Future<List<Location>> locationFromAddress(
    String address, {
    Locale? locale,
  }) async {
    if (failForward case final error?) throw error;
    return hits[address.toLowerCase()] ?? const [];
  }

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) async {
    final mark = names[key(latitude, longitude)]?[locale?.languageCode];
    return [?mark];
  }

  @override
  Future<List<Placemark>> placemarkFromAddress(
    String address, {
    Locale? locale,
  }) => throw UnimplementedError();

  @override
  Future<bool> isPresent() async => true;

  @override
  // ignore: deprecated_member_use
  void setLocaleIdentifier(String localeIdentifier) {}
}

Location _at(double lat, double lng) =>
    Location(latitude: lat, longitude: lng, timestamp: DateTime(2026));

void main() {
  late SharedPreferences prefs;
  late _FakeGeocoding geocoding;
  late DeviceLocationService service;

  final alexandriaNames = {
    'en': Placemark(
      locality: 'Alexandria',
      country: 'Egypt',
      isoCountryCode: 'EG',
    ),
    'ar': Placemark(
      locality: 'الإسكندرية',
      country: 'مصر',
      isoCountryCode: 'EG',
    ),
  };
  final virginiaNames = {
    'en': Placemark(
      locality: 'Alexandria',
      country: 'United States',
      isoCountryCode: 'US',
    ),
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'last_location':
          '{"lat":30.0444,"lng":31.2357,'
          '"updatedAt":"2026-10-13T09:00:00.000Z",'
          '"names":{"en":{"city":"Cairo","country":"Egypt"}}}',
    });
    prefs = await SharedPreferences.getInstance();
    geocoding = _FakeGeocoding(
      hits: {
        'alex': [
          _at(31.2001, 29.9187),
          // The same city again, a little off its centre.
          _at(31.2050, 29.9200),
          _at(38.8048, -77.0469),
          // Nothing to name here: dropped.
          _at(0, -30),
        ],
      },
      names: {
        _FakeGeocoding.key(31.2001, 29.9187): alexandriaNames,
        _FakeGeocoding.key(31.2050, 29.9200): alexandriaNames,
        _FakeGeocoding.key(38.8048, -77.0469): virginiaNames,
      },
    );
    service = DeviceLocationService(prefs, geocoding: geocoding);
  });

  group('search', () {
    test('names each hit in both languages, without duplicates', () async {
      final results = await service.searchPlaces('Alex');

      expect(results, hasLength(2));
      final egypt = results.first;
      expect(
        egypt.placeName('en'),
        const PlaceName(city: 'Alexandria', country: 'Egypt'),
      );
      expect(egypt.placeName('ar')!.city, 'الإسكندرية');
      expect(egypt.countryCode, 'EG');
      expect(results.last.placeName('en')!.country, 'United States');
      expect(results.last.countryCode, 'US');
    });

    test('nothing found is an empty list', () async {
      expect(await service.searchPlaces('Atlantis'), isEmpty);
    });

    test('a failed lookup is a PlaceSearchException', () async {
      geocoding.failForward = PlatformException(code: 'IO_ERROR');
      expect(
        service.searchPlaces('Alex'),
        throwsA(isA<PlaceSearchException>()),
      );
    });
  });

  group('a chosen city', () {
    test('replaces the device location and survives a restart', () async {
      expect(service.isManual, isFalse);
      expect(service.lastKnown!.placeName('en')!.city, 'Cairo');

      final changes = <UserLocation>[];
      service.changes.listen(changes.add);
      await service.useManualLocation(alexandria);
      await pumpEventQueue();

      expect(service.isManual, isTrue);
      expect(service.lastKnown, alexandria);
      expect(changes, [alexandria]);

      final restarted = DeviceLocationService(prefs, geocoding: geocoding);
      expect(restarted.isManual, isTrue);
      expect(restarted.lastKnown, alexandria);
      expect(restarted.lastKnown!.countryCode, 'EG');
    });

    test('is what locate returns, without asking the device', () async {
      await service.useManualLocation(alexandria);
      // A device lookup would hit the geolocator plugin, which has no
      // implementation in tests and would throw.
      final result = await service.locate();
      expect(result, isA<LocationFound>());
      expect((result as LocationFound).location, alexandria);
    });
  });
}
