import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';
import 'home_header.dart';

enum StatusTone { danger, gold }

/// The fallback note under the body: a gold clock tile with two lines.
class StatusNote {
  const StatusNote({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

/// Full-screen status: icon in a dashed halo, title, body, an optional
/// [note], a primary action and an optional text action.
class LocationStatusView extends StatelessWidget {
  const LocationStatusView({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.note,
  });

  final HayyaIconData icon;
  final StatusTone tone;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final StatusNote? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final (Color iconBg, Color iconInk) = switch (tone) {
      StatusTone.danger => (c.dangerSoft, c.danger),
      StatusTone.gold => (c.goldSoft, c.goldInk),
    };

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 14.r,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(bottom: 10.r),
          child: CustomPaint(
            foregroundPainter: _DashedHalo(color: c.line, gap: 14.r),
            child: Container(
              width: 120.r,
              height: 120.r,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: HayyaIcon(
                icon,
                size: 54,
                color: iconInk,
                strokeWidth: 1.6,
              ),
            ),
          ),
        ),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: type
                .style(24, FontWeight.w800, height: 1.35)
                .copyWith(color: c.text),
          ),
        ),
        Text(
          body,
          textAlign: TextAlign.center,
          style: type
              .style(15.5, FontWeight.w500, height: type.isArabic ? 1.8 : 1.6)
              .copyWith(color: c.muted),
        ),
        if (note != null) _Note(note!),
        Padding(
          padding: EdgeInsetsDirectional.only(top: HayyaSpacing.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: HayyaSpacing.s2,
            children: [
              HayyaButton(
                label: primaryLabel,
                onPressed: onPrimary,
                expand: true,
              ),
              if (secondaryLabel != null)
                HayyaButton(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  variant: HayyaButtonVariant.text,
                  expand: true,
                ),
            ],
          ),
        ),
      ],
    );

    return Stack(
      children: [
        // The pattern fades in from the top, as on the Home header.
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          height: 420.r,
          child: CustomPaint(
            painter: HeaderPatternPainter(
              color: c.primaryInk.withValues(alpha: 0.07),
              tile: 56.r,
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 30.r),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    // Phone width on tablets.
                    constraints: BoxConstraints(maxWidth: 400.r),
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        vertical: HayyaSpacing.s6,
                      ),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.note);

  final StatusNote note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: HayyaSpacing.s1),
      child: HayyaCard(
        radius: 18.r,
        padding: EdgeInsetsDirectional.all(14.r),
        child: Row(
          spacing: HayyaSpacing.s3,
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.goldSoft,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: HayyaIcon(
                HayyaIcons.reminder,
                size: 18,
                color: c.goldInk,
                strokeWidth: 2,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1.r,
                children: [
                  Text(
                    note.title,
                    style: type
                        .style(14.5, FontWeight.w700)
                        .copyWith(color: c.text),
                  ),
                  Text(
                    note.subtitle,
                    style: type
                        .style(12.5, FontWeight.w600)
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

/// Dashed circle [gap] outside the child's bounds.
class _DashedHalo extends CustomPainter {
  const _DashedHalo({required this.color, required this.gap});

  final Color color;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 + gap;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashes = 36;
    const sweep = 2 * math.pi / dashes;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedHalo old) => old.color != color || old.gap != gap;
}
