import 'heading_math.dart';

/// Decides when the phone faces the Qibla.
///
/// Aligned within [enterWithin] degrees, and stays aligned until it drifts
/// past [leaveBeyond]. The gap keeps a hand-held phone hovering at the
/// edge from flickering in and out (and buzzing on every flicker).
class AlignmentTracker {
  AlignmentTracker({this.enterWithin = 3, this.leaveBeyond = 5})
    : assert(enterWithin > 0 && leaveBeyond >= enterWithin);

  final double enterWithin;
  final double leaveBeyond;

  bool _aligned = false;

  bool get aligned => _aligned;

  /// Updates with the phone's [heading] and returns whether it is aligned
  /// with [bearing]. Both in degrees from north.
  bool update({required double heading, required double bearing}) {
    final off = shortestTurn(heading, bearing).abs();
    return _aligned = _aligned ? off <= leaveBeyond : off <= enterWithin;
  }

  void reset() => _aligned = false;
}
