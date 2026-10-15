import 'dart:math' as math;

import '../../../core/services/user_location.dart';

/// The Kaaba, Makkah.
const kaaba = GeoCoordinates(21.4225241, 39.8261818);

/// Great-circle bearing from [from] to the Kaaba, in degrees clockwise
/// from true north (0–360).
double qiblaBearing(GeoCoordinates from) {
  double rad(double deg) => deg * math.pi / 180;
  final lat = rad(from.latitude);
  final dLng = rad(kaaba.longitude - from.longitude);
  final kaabaLat = rad(kaaba.latitude);
  final y = math.sin(dLng);
  final x = math.cos(lat) * math.tan(kaabaLat) - math.sin(lat) * math.cos(dLng);
  final deg = math.atan2(y, x) * 180 / math.pi;
  return (deg + 360) % 360;
}

enum CompassPoint { n, ne, e, se, s, sw, w, nw }

/// The nearest of the eight compass points to [bearing].
CompassPoint compassPoint(double bearing) =>
    CompassPoint.values[((bearing % 360 + 22.5) ~/ 45) % 8];
