import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/compass_sensor.dart';

/// "Calibrate your compass": a traced figure 8, the steps, and how
/// accurate the compass is now.
class CalibrationCard extends StatelessWidget {
  const CalibrationCard({super.key, required this.accuracy});

  final CompassAccuracy? accuracy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final level = accuracy ?? CompassAccuracy.low;
    final (progress, label) = switch (level) {
      CompassAccuracy.low => (0.4, LocaleKeys.qibla_accuracy_low),
      CompassAccuracy.medium => (0.7, LocaleKeys.qibla_accuracy_medium),
      CompassAccuracy.high => (1.0, LocaleKeys.qibla_accuracy_high),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(HayyaSpacing.s6),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(24.r),
          // Floats over the dial.
          boxShadow: c.heroShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: HayyaSpacing.s3,
          children: [
            SizedBox(width: 150.r, height: 80.r, child: const _FigureEight()),
            Semantics(
              header: true,
              child: Text(
                LocaleKeys.qibla_calibrate_title.tr(),
                textAlign: TextAlign.center,
                style: type.style(20, FontWeight.w800).copyWith(color: c.text),
              ),
            ),
            Text(
              LocaleKeys.qibla_calibrate_body.tr(),
              textAlign: TextAlign.center,
              style: type
                  .style(15, FontWeight.w500, height: type.isArabic ? 1.8 : 1.6)
                  .copyWith(color: c.muted),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(top: HayyaSpacing.s1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(HayyaRadius.full),
                child: SizedBox(
                  height: 8.r,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: c.surface2)),
                      FractionallySizedBox(
                        widthFactor: progress,
                        heightFactor: 1,
                        alignment: AlignmentDirectional.centerStart,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.gold,
                            borderRadius: BorderRadius.circular(
                              HayyaRadius.full,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              label.tr(),
              style: type.style(13, FontWeight.w700).copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The figure 8 with a gold dash running along it (still when the system
/// asks for reduced motion).
class _FigureEight extends StatefulWidget {
  const _FigureEight();

  @override
  State<_FigureEight> createState() => _FigureEightState();
}

class _FigureEightState extends State<_FigureEight>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      painter: _FigureEightPainter(
        progress: _controller,
        track: c.line,
        trace: c.gold,
      ),
    );
  }
}

class _FigureEightPainter extends CustomPainter {
  _FigureEightPainter({
    required this.progress,
    required this.track,
    required this.trace,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color track;
  final Color trace;

  /// The design's path, in its 24 × 12.8 viewBox.
  static final _path = Path()
    ..moveTo(12, 6.4)
    ..relativeCubicTo(-2, -2.6, -3.6, -4, -5.5, -4)
    ..relativeArcToPoint(
      const Offset(0, 8),
      radius: const Radius.circular(4),
      clockwise: false,
    )
    ..relativeCubicTo(1.9, 0, 3.5, -1.4, 5.5, -4)
    ..close()
    ..moveTo(12, 6.4)
    ..relativeCubicTo(2, 2.6, 3.6, 4, 5.5, 4)
    ..relativeArcToPoint(
      const Offset(0, -8),
      radius: const Radius.circular(4),
      clockwise: false,
    )
    ..relativeCubicTo(-1.9, 0, -3.5, 1.4, -5.5, 4)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 24, size.height / 12.8);
    canvas.save();
    canvas.translate(
      (size.width - 24 * scale) / 2,
      (size.height - 12.8 * scale) / 2,
    );
    canvas.scale(scale);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      _path,
      stroke
        ..color = track
        ..strokeWidth = 1.6,
    );

    // Dashes of 10 with gaps of 7, moving 34 units per cycle (as the
    // design's stroke-dashoffset animation).
    stroke
      ..color = trace
      ..strokeWidth = 1.2;
    final shift = progress.value * 34;
    for (final PathMetric metric in _path.computeMetrics()) {
      for (var start = shift - 34; start < metric.length; start += 17) {
        final from = math.max(0.0, start);
        final to = math.min(metric.length, start + 10);
        if (to > from) canvas.drawPath(metric.extractPath(from, to), stroke);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigureEightPainter old) =>
      old.track != track || old.trace != trace;
}

/// "No compass sensor": how to find the Qibla with the bearing alone.
class NoSensorCard extends StatelessWidget {
  const NoSensorCard({super.key, required this.bearing});

  final double bearing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Semantics(
      container: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(18.r),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14.r,
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.goldSoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: HayyaIcon(HayyaIcons.qiblaOff, size: 22, color: c.goldInk),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6.r,
                children: [
                  Text(
                    LocaleKeys.qibla_no_sensor_title.tr(),
                    style: type
                        .style(16, FontWeight.w700)
                        .copyWith(color: c.text),
                  ),
                  Text(
                    LocaleKeys.qibla_no_sensor_body.tr(
                      args: [context.format.number(bearing.round() % 360)],
                    ),
                    style: type
                        .style(
                          14,
                          FontWeight.w500,
                          height: type.isArabic ? 1.8 : 1.65,
                        )
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
