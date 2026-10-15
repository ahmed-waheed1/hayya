/// [degrees] folded into 0 ≤ x < 360.
double normalizeDegrees(double degrees) {
  final folded = degrees % 360;
  return folded < 0 ? folded + 360 : folded;
}

/// The shortest turn from [from] to [to], in degrees: positive clockwise,
/// negative counter-clockwise, within (−180, 180].
double shortestTurn(double from, double to) {
  final delta = normalizeDegrees(to - from);
  return delta > 180 ? delta - 360 : delta;
}

/// Low-pass filter for compass headings.
///
/// [value] is unwrapped: it keeps counting past 360 or below 0 instead of
/// jumping, so a needle rotated by it always takes the short way round
/// (359° → 1° turns 2°, not 358° backwards).
class HeadingSmoother {
  HeadingSmoother({this.smoothing = 0.25})
    : assert(smoothing > 0 && smoothing <= 1);

  /// Weight of each new reading, 0–1. Lower is steadier but slower.
  final double smoothing;

  double? _value;

  /// The smoothed, unwrapped heading; null before the first reading.
  double? get value => _value;

  /// Folds [heading] (0–360) into the smoothed value and returns it.
  double add(double heading) {
    final current = _value;
    return _value = current == null
        ? normalizeDegrees(heading)
        : current + smoothing * shortestTurn(current, heading);
  }

  void reset() => _value = null;
}
