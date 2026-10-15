import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';

/// Loading placeholders shaped like the Home header, hero card and list.
/// Bone widths for the six rows vary so the list doesn't look stamped.
const _rowNameWidths = [70.0, 84.0, 62.0, 52.0, 90.0, 58.0];

/// Shimmering bones on a [base] color.
class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.base, required this.child});

  final Color base;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Skeletonizer.zone(
      effect: ShimmerEffect(
        baseColor: base,
        highlightColor: context.isDark ? c.selectedSurface : c.surface,
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.centerEnd,
      ),
      child: child,
    );
  }
}

Widget _bone(double width, double height, double radius) => Bone(
  width: width.r,
  height: height.r,
  borderRadius: BorderRadius.circular(radius.r),
);

class SkeletonHeader extends StatelessWidget {
  const SkeletonHeader({super.key, this.tablet = false});

  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: c.surface2,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          top: top + (tablet ? 40.r : HayyaSpacing.s2),
          start: tablet ? 40.r : HayyaSpacing.screenGutter,
        ),
        child: _Shimmer(
          base: c.line,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14.r,
            children: tablet
                ? [_bone(170, 44, 14), _bone(260, 16, 6), _bone(200, 16, 6)]
                : [_bone(130, 40, 14), _bone(210, 14, 6), _bone(160, 14, 6)],
          ),
        ),
      ),
    );
  }
}

class SkeletonHeroCard extends StatelessWidget {
  const SkeletonHeroCard({super.key, this.tablet = false});

  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ring = Container(
      width: (tablet ? 240 : 112).r,
      height: (tablet ? 240 : 112).r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.surface2, width: (tablet ? 14 : 9).r),
      ),
    );

    return HayyaCard(
      radius: HayyaRadius.xxl,
      padding: EdgeInsetsDirectional.all((tablet ? 32 : 20).r),
      child: _Shimmer(
        base: c.surface2,
        child: tablet
            ? Column(
                spacing: 22.r,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _bone(100, 12, 6),
                  ),
                  ring,
                  _bone(180, 48, 10),
                ],
              )
            : SizedBox(
                height: 116.r,
                child: Row(
                  spacing: HayyaSpacing.s4,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: HayyaSpacing.s3,
                        children: [
                          _bone(90, 11, 6),
                          _bone(110, 22, 8),
                          _bone(150, 30, 8),
                        ],
                      ),
                    ),
                    ring,
                  ],
                ),
              ),
      ),
    );
  }
}

/// Phone: the "Today" title bone and the row card. Tablet: one card with
/// the title inside, like [PrayerList].
class SkeletonPrayerList extends StatelessWidget {
  const SkeletonPrayerList({super.key, this.tablet = false});

  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = [
      for (final width in _rowNameWidths)
        SizedBox(
          height: (tablet ? 76 : 54).r,
          child: Row(
            spacing: (tablet ? 16 : 12).r,
            children: [
              tablet ? _bone(46, 46, 14) : _bone(34, 34, 11),
              _bone(tablet ? width * 1.3 : width, tablet ? 18 : 14, 6),
              const Spacer(),
              _bone(tablet ? 84 : 64, tablet ? 18 : 14, 6),
              tablet ? _bone(28, 28, 9) : _bone(26, 26, 9),
            ],
          ),
        ),
    ];

    if (tablet) {
      return HayyaCard(
        radius: HayyaRadius.xxl,
        padding: EdgeInsetsDirectional.fromSTEB(36.r, 28.r, 28.r, 20.r),
        child: _Shimmer(
          base: c.surface2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: HayyaSpacing.s2,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: 12.r),
                child: _bone(90, 20, 6),
              ),
              ...rows,
            ],
          ),
        ),
      );
    }

    return _Shimmer(
      base: c.surface2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(4.r, 26.r, 4.r, 12.r),
            child: _bone(80, 16, 6),
          ),
          HayyaCard(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 14.r,
              vertical: 10.r,
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}
