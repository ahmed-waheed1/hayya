import 'dart:math' as math;

import '../../../core/services/user_location.dart';
import 'wmm2025_coefficients.dart';

/// Magnetic declination at [at] on [date], in degrees: how far magnetic
/// north lies east (+) or west (−) of true north. Add it to a magnetic
/// heading to get a true one.
///
/// World Magnetic Model (WMM2025, see [wmmValidUntil]), at
/// [altitudeKm] above the WGS84 ellipsoid.
double magneticDeclination(
  GeoCoordinates at,
  DateTime date, {
  double altitudeKm = 0,
}) => _declination(
  latitude: at.latitude,
  longitude: at.longitude,
  decimalYear: decimalYear(date),
  altitudeKm: altitudeKm,
);

/// [date] as a decimal year, by day as NOAA's calculator counts it:
/// 15 October 2026 (day 288) is 2026 + 287 / 365 = 2026.7863.
double decimalYear(DateTime date) {
  final start = DateTime.utc(date.year);
  final day = DateTime.utc(date.year, date.month, date.day);
  final yearDays = DateTime.utc(date.year + 1).difference(start).inDays;
  return date.year + day.difference(start).inDays / yearDays;
}

/// For tests against NOAA's published values, which are in decimal years.
double declinationAt({
  required double latitude,
  required double longitude,
  required double decimalYear,
  double altitudeKm = 0,
}) => _declination(
  latitude: latitude,
  longitude: longitude,
  decimalYear: decimalYear,
  altitudeKm: altitudeKm,
);

const _maxDegree = 12;

/// WGS84 ellipsoid.
const _a = 6378.137;
const _f = 1 / 298.257223563;
const _e2 = _f * (2 - _f);

/// The model's reference radius, in km.
const _referenceRadius = 6371.2;

double _rad(double deg) => deg * math.pi / 180;

/// Follows the WMM2025 technical report, sections 1.2 and 1.3.
double _declination({
  required double latitude,
  required double longitude,
  required double decimalYear,
  required double altitudeKm,
}) {
  // Geodetic → geocentric spherical (eq. 7–8).
  final phi = _rad(latitude);
  final lambda = _rad(longitude);
  final sinPhi = math.sin(phi);
  final rc = _a / math.sqrt(1 - _e2 * sinPhi * sinPhi);
  final p = (rc + altitudeKm) * math.cos(phi);
  final z = (rc * (1 - _e2) + altitudeKm) * sinPhi;
  final r = math.sqrt(p * p + z * z);
  final phiC = math.asin(z / r); // geocentric latitude

  // Colatitude; kept off the poles, where east is undefined.
  final theta = (math.pi / 2 - phiC).clamp(1e-9, math.pi - 1e-9);
  final legendre = _SchmidtLegendre(theta);
  final sinTheta = math.sin(theta);

  final dt = decimalYear - wmmEpoch;
  var north = 0.0, east = 0.0, down = 0.0;
  for (final (n, m, g0, h0, gDot, hDot) in wmmCoefficients) {
    final g = g0 + dt * gDot;
    final h = h0 + dt * hDot;
    final ratio = math.pow(_referenceRadius / r, n + 2).toDouble();
    final cosM = math.cos(m * lambda);
    final sinM = math.sin(m * lambda);
    final gh = g * cosM + h * sinM;
    north += ratio * gh * legendre.dp(n, m);
    east += ratio * m * (g * sinM - h * cosM) * legendre.p(n, m) / sinTheta;
    down -= ratio * (n + 1) * gh * legendre.p(n, m);
  }

  // Geocentric → geodetic frame (eq. 17); east is unchanged.
  final psi = phiC - phi;
  final northGeodetic = north * math.cos(psi) - down * math.sin(psi);

  return math.atan2(east, northGeodetic) * 180 / math.pi;
}

/// Schmidt semi-normalized associated Legendre functions P(n, m)(cos θ)
/// and their derivatives with respect to the colatitude θ, up to degree
/// [_maxDegree].
class _SchmidtLegendre {
  _SchmidtLegendre(double theta) {
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);
    // Gauss-normalized recursion, then scaled to Schmidt.
    _p[_i(0, 0)] = 1;
    _dp[_i(0, 0)] = 0;
    for (var n = 1; n <= _maxDegree; n++) {
      for (var m = 0; m <= n; m++) {
        final i = _i(n, m);
        if (n == m) {
          final j = _i(n - 1, m - 1);
          _p[i] = sinT * _p[j];
          _dp[i] = sinT * _dp[j] + cosT * _p[j];
        } else {
          final j = _i(n - 1, m);
          final k = n > 1 && m <= n - 2
              ? ((n - 1) * (n - 1) - m * m) / ((2 * n - 1) * (2 * n - 3))
              : 0.0;
          final p2 = k == 0 ? 0.0 : _p[_i(n - 2, m)];
          final dp2 = k == 0 ? 0.0 : _dp[_i(n - 2, m)];
          _p[i] = cosT * _p[j] - k * p2;
          _dp[i] = cosT * _dp[j] - sinT * _p[j] - k * dp2;
        }
      }
    }
    for (var n = 1; n <= _maxDegree; n++) {
      var s = _schmidt0(n);
      for (var m = 0; m <= n; m++) {
        if (m > 0) s *= math.sqrt((n - m + 1) * (m == 1 ? 2 : 1) / (n + m));
        _p[_i(n, m)] *= s;
        _dp[_i(n, m)] *= s;
      }
    }
  }

  final _p = List<double>.filled(_i(_maxDegree, _maxDegree) + 1, 0);
  final _dp = List<double>.filled(_i(_maxDegree, _maxDegree) + 1, 0);

  static int _i(int n, int m) => n * (n + 1) ~/ 2 + m;

  /// (2n − 1)!! / n!, the m = 0 factor.
  static double _schmidt0(int n) {
    var s = 1.0;
    for (var k = 1; k <= n; k++) {
      s *= (2 * k - 1) / k;
    }
    return s;
  }

  double p(int n, int m) => _p[_i(n, m)];
  double dp(int n, int m) => _dp[_i(n, m)];
}
