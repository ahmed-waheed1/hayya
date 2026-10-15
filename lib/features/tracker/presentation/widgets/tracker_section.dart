import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';

/// A tracker card: [title] with a muted [caption] at the end, then
/// [child].
class TrackerSection extends StatelessWidget {
  const TrackerSection({
    super.key,
    required this.title,
    this.caption,
    this.spacing = 12,
    required this.child,
  });

  final String title;
  final String? caption;

  /// Design px between the heading and [child].
  final double spacing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return HayyaCard(
      padding: EdgeInsetsDirectional.fromSTEB(16.r, 18.r, 16.r, 16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.r,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 12.r,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: type
                        .style(16, FontWeight.w800)
                        .copyWith(color: c.text),
                  ),
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: type
                      .style(12.5, FontWeight.w600)
                      .copyWith(color: c.muted),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

/// A tinted note with a leading icon (the chart's tip).
class TrackerNote extends StatelessWidget {
  const TrackerNote({
    super.key,
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final HayyaIconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 12.r,
        vertical: 10.r,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        spacing: 8.r,
        children: [
          HayyaIcon(icon, size: 18, color: foreground, strokeWidth: 1.9),
          Expanded(
            child: Text(
              text,
              style: context.type
                  .style(13, FontWeight.w700)
                  .copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
