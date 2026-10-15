import 'package:equatable/equatable.dart';

class GeoCoordinates extends Equatable {
  const GeoCoordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// A place's name in one language. Either part can be missing.
class PlaceName extends Equatable {
  const PlaceName({this.city, this.country});

  final String? city;
  final String? country;

  Map<String, Object?> toJson() => {'city': city, 'country': country};

  factory PlaceName.fromJson(Map<String, Object?> json) => PlaceName(
    city: json['city'] as String?,
    country: json['country'] as String?,
  );

  @override
  List<Object?> get props => [city, country];
}

/// Where the user is, as of [updatedAt].
class UserLocation extends Equatable {
  const UserLocation({
    required this.coordinates,
    required this.updatedAt,
    this.placeNames = const {},
  });

  final GeoCoordinates coordinates;
  final DateTime updatedAt;

  /// Reverse-geocoded names keyed by language code ('en', 'ar'). Empty
  /// when geocoding failed (offline).
  final Map<String, PlaceName> placeNames;

  /// The name in [languageCode], falling back to any language we have.
  PlaceName? placeName(String languageCode) =>
      placeNames[languageCode] ?? placeNames.values.firstOrNull;

  Map<String, Object?> toJson() => {
    'lat': coordinates.latitude,
    'lng': coordinates.longitude,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'names': {
      for (final MapEntry(:key, :value) in placeNames.entries)
        key: value.toJson(),
    },
  };

  factory UserLocation.fromJson(Map<String, Object?> json) => UserLocation(
    coordinates: GeoCoordinates(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    ),
    updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    placeNames: {
      for (final MapEntry(:key, :value)
          in ((json['names'] as Map?) ?? const {}).entries)
        key as String: PlaceName.fromJson(
          (value as Map).cast<String, Object?>(),
        ),
    },
  );

  @override
  List<Object?> get props => [coordinates, updatedAt, placeNames];
}
