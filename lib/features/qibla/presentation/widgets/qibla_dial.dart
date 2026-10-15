import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../core/theme/hayya_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/heading_math.dart';

/// The Qibla compass from the design's QiblaDial.
///
/// The card turns with the phone ([heading]) so north stays north; the
/// needle stays put and points where the phone points. The Kaaba sits on
/// the card at [bearing]. With no [heading] (no compass) the card shows
/// north up, without a needle, and a gold line runs to the Kaaba.
///
/// Physical, so never mirrored in RTL.
class QiblaDial extends StatelessWidget {
  const QiblaDial({
    super.key,
    required this.bearing,
    required this.heading,
    required this.aligned,
    required this.size,
    required this.semanticLabel,
    this.dimmed = false,
  });

  final double bearing;

  /// Unwrapped heading (see [HeadingSmoother]); null without a compass.
  final double? heading;
  final bool aligned;
  final double size;
  final String semanticLabel;

  /// Faded behind the calibration card.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final glow = c.primary;

    return Semantics(
      image: true,
      label: semanticLabel,
      child: AnimatedOpacity(
        opacity: dimmed ? 0.3 : 1,
        duration: const Duration(milliseconds: 250),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            boxShadow: aligned
                ? [
                    BoxShadow(
                      color: glow.withValues(
                        alpha: context.isDark ? 0.14 : 0.1,
                      ),
                      spreadRadius: size * 10 / 300,
                    ),
                    BoxShadow(
                      color: glow.withValues(
                        alpha: context.isDark ? 0.5 : 0.35,
                      ),
                      blurRadius: size * 70 / 300,
                    ),
                  ]
                : c.cardShadow,
          ),
          // Short easing between ~30 Hz sensor samples, so the card moves
          // smoothly at the display's frame rate. The heading is unwrapped,
          // so this never spins the long way round.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: heading ?? 0),
            duration: const Duration(milliseconds: 90),
            builder: (context, animated, _) => CustomPaint(
              size: Size.square(size),
              painter: QiblaDialPainter(
                colors: c,
                bearing: bearing,
                heading: heading == null ? null : animated,
                aligned: aligned,
                northStyle: type.style(17, FontWeight.w800),
                pointStyle: type.style(15, FontWeight.w700),
                labels: (
                  n: LocaleKeys.qibla_dial_n.tr(),
                  e: LocaleKeys.qibla_dial_e.tr(),
                  s: LocaleKeys.qibla_dial_s.tr(),
                  w: LocaleKeys.qibla_dial_w.tr(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef CardinalLabels = ({String n, String e, String s, String w});

/// Paints the dial in the design's 300 × 300 space, scaled to fit.
class QiblaDialPainter extends CustomPainter {
  QiblaDialPainter({
    required this.colors,
    required this.bearing,
    required this.heading,
    required this.aligned,
    required this.northStyle,
    required this.pointStyle,
    required this.labels,
  });

  final HayyaColors colors;
  final double bearing;
  final double? heading;
  final bool aligned;
  final TextStyle northStyle;
  final TextStyle pointStyle;
  final CardinalLabels labels;

  /// The Kaaba's black cloth and gold band. Illustration colors, the same
  /// in both themes (from the Qibla frame), so not theme tokens.
  static const kaabaCloth = Color(0xFF15130F);
  static const kaabaBand = Color(0xFFD9AE5B);

  static const _design = 300.0;
  static const _center = Offset(150, 150);

  /// Point at [radius] from the center, [degrees] clockwise from the top.
  static Offset _polar(double degrees, double radius) {
    final rad = degrees * math.pi / 180;
    return _center + Offset(math.sin(rad), -math.cos(rad)) * radius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _design);

    final live = heading != null;
    final needle = aligned ? colors.gold : colors.primary;

    // Outer ring: thicker and primary while aligned.
    canvas.drawCircle(
      _center,
      146,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = aligned ? colors.primary : colors.line
        ..strokeWidth = aligned ? 5 : 2,
    );

    // The card, turned so north stays north.
    canvas.save();
    canvas.translate(_center.dx, _center.dy);
    canvas.rotate(-(heading ?? 0) * math.pi / 180);
    canvas.translate(-_center.dx, -_center.dy);
    _paintTicks(canvas);
    _paintCardinals(canvas);
    _paintKaaba(canvas, line: !live);
    canvas.restore();

    if (live) {
      _paintTurnArc(canvas);
      _paintNeedle(canvas, needle);
    }
    canvas.restore();
  }

  void _paintTicks(Canvas canvas) {
    // Every 5°, faint; every 30°, in text color.
    final minor = Paint()
      ..color = colors.faint.withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    final major = Paint()
      ..color = colors.text.withValues(alpha: 0.8)
      ..strokeWidth = 2.4;
    for (var deg = 0; deg < 360; deg += 5) {
      if (deg % 30 == 0) {
        canvas.drawLine(
          _polar(deg.toDouble(), 122.5),
          _polar(deg.toDouble(), 133.5),
          major,
        );
      } else {
        canvas.drawLine(
          _polar(deg.toDouble(), 124.5),
          _polar(deg.toDouble(), 131.5),
          minor,
        );
      }
    }
  }

  void _paintCardinals(Canvas canvas) {
    for (final (deg, text, style, size, radius, color) in [
      (0.0, labels.n, northStyle, 17.0, 112.0, colors.danger),
      (90.0, labels.e, pointStyle, 15.0, 108.0, colors.muted),
      (180.0, labels.s, pointStyle, 15.0, 108.0, colors.muted),
      (270.0, labels.w, pointStyle, 15.0, 108.0, colors.muted),
    ]) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          // The canvas is already in design units, so the design's size,
          // not ScreenUtil's.
          style: style.copyWith(color: color, fontSize: size, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = _polar(deg, radius);
      painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
      painter.dispose();
    }
  }

  void _paintKaaba(Canvas canvas, {required bool line}) {
    final at = _polar(bearing, 106);
    if (line) {
      _paintDashedLine(canvas, _center, at);
    }

    final halo = aligned ? 0.35 : (line ? 0.18 : 0.0);
    if (halo > 0) {
      canvas.drawCircle(
        at,
        21,
        Paint()..color = kaabaBand.withValues(alpha: halo),
      );
    }

    // Kept upright on screen while the card turns.
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate((heading ?? 0) * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -12, 24, 24),
        const Radius.circular(4),
      ),
      Paint()..color = kaabaCloth,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-12, -6, 24, 3.5),
      Paint()..color = kaabaBand,
    );
    canvas.restore();
  }

  void _paintDashedLine(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = colors.gold
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final total = (to - from).distance;
    final direction = (to - from) / total;
    for (var d = 0.0; d < total; d += 12) {
      final end = math.min(d + 6, total);
      canvas.drawLine(from + direction * d, from + direction * end, paint);
    }
  }

  /// Gold arc from where the phone points to the Kaaba, the short way.
  void _paintTurnArc(Canvas canvas) {
    if (aligned) return;
    final turn = shortestTurn(heading!, bearing);
    canvas.drawArc(
      Rect.fromCircle(center: _center, radius: 146),
      -math.pi / 2,
      turn * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = colors.gold.withValues(alpha: 0.9)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintNeedle(Canvas canvas, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(150, 40)
        ..lineTo(161, 150)
        ..lineTo(150, 162)
        ..lineTo(139, 150)
        ..close(),
      Paint()..color = color,
    );
    canvas.drawPath(
      Path()
        ..moveTo(139, 150)
        ..lineTo(150, 162)
        ..lineTo(161, 150)
        ..lineTo(150, 238)
        ..close(),
      Paint()..color = colors.line,
    );
    canvas.drawCircle(_center, 11, Paint()..color = colors.surface);
    canvas.drawCircle(
      _center,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(QiblaDialPainter old) =>
      old.heading != heading ||
      old.bearing != bearing ||
      old.aligned != aligned ||
      old.colors != colors ||
      old.labels != labels ||
      old.northStyle != northStyle;
}
