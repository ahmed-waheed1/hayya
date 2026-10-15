import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/theme_context.dart';

/// Progress ring around the countdown: a primary arc from the top with a
/// gold dot at its end. Fills clockwise in LTR, counter-clockwise in RTL.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.progress,
    required this.size,
    required this.stroke,
    required this.dotRadius,
    required this.dotStroke,
    required this.semanticLabel,
    required this.child,
  });

  /// 0–1.
  final double progress;

  /// Design sizes, scaled with ScreenUtil.
  final double size;
  final double stroke;
  final double dotRadius;
  final double dotStroke;

  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size.r,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Transform.flip(
                flipX: rtl,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    stroke: stroke.r,
                    dotRadius: dotRadius.r,
                    dotStroke: dotStroke.r,
                    track: c.surface2,
                    arc: c.primary,
                    dot: c.gold,
                    dotOutline: c.surface,
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.stroke,
    required this.dotRadius,
    required this.dotStroke,
    required this.track,
    required this.arc,
    required this.dot,
    required this.dotOutline,
  });

  final double progress;
  final double stroke;
  final double dotRadius;
  final double dotStroke;
  final Color track;
  final Color arc;
  final Color dot;
  final Color dotOutline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Inset so the dot (radius + outline) stays inside the box.
    final radius =
        size.shortestSide / 2 - math.max(stroke / 2, dotRadius + dotStroke / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, line..color = track);
    final sweep = 2 * math.pi * progress;
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, line..color = arc);
    }

    final angle = -math.pi / 2 + sweep;
    final dotCenter =
        center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas
      ..drawCircle(dotCenter, dotRadius, Paint()..color = dot)
      ..drawCircle(
        dotCenter,
        dotRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = dotStroke
          ..color = dotOutline,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.dotRadius != dotRadius ||
      old.dotStroke != dotStroke ||
      old.track != track ||
      old.arc != arc ||
      old.dot != dot ||
      old.dotOutline != dotOutline;
}
