import 'dart:math' as math;

import 'package:adhan/adhan.dart' as adhan;

import '../../../core/services/user_location.dart';

/// The Kaaba, Makkah (the point adhan's [adhan.Qibla] aims at).
final kaaba = GeoCoordinates(
  adhan.Qibla.MAKKAH.latitude,
  adhan.Qibla.MAKKAH.longitude,
);

/// Mean Earth radius (IUGG), in km.
const _earthRadiusKm = 6371.0088;

/// Great-circle bearing from [from] to the Kaaba, in degrees clockwise
/// from true north (0–360).
double qiblaBearing(GeoCoordinates from) =>
    adhan.Qibla(adhan.Coordinates(from.latitude, from.longitude)).direction;

/// Great-circle (haversine) distance from [from] to the Kaaba, in km.
double distanceToKaabaKm(GeoCoordinates from) {
  double rad(double deg) => deg * math.pi / 180;
  final lat1 = rad(from.latitude);
  final lat2 = rad(kaaba.latitude);
  final dLat = lat2 - lat1;
  final dLng = rad(kaaba.longitude - from.longitude);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(a.clamp(0, 1)));
}

enum CompassPoint { n, ne, e, se, s, sw, w, nw }

/// The nearest of the eight compass points to [bearing].
CompassPoint compassPoint(double bearing) =>
    CompassPoint.values[((bearing % 360 + 22.5) ~/ 45) % 8];
