import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/presentation/widgets/location_status_view.dart';

/// A slide's illustration: a soft circle with a dashed gold halo, the
/// primary tile inside it with the brand mark ([icon] null) or an icon,
/// and an optional [badge] card at its bottom end.
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({
    super.key,
    this.icon,
    this.badge,
    this.badgeIcon,
    required this.maxWidth,
  });

  final HayyaIconData? icon;
  final String? badge;
  final HayyaIconData? badgeIcon;

  /// The width the hero is centered in, so a long badge stays on screen.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final circle = 236.r;
    return SizedBox.square(
      dimension: circle,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            foregroundPainter: DashedHalo(
              color: c.gold.withValues(alpha: 0.55),
              gap: 18.r,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: circle),
            ),
          ),
          _Tile(icon: icon),
          if (badge case final badge?)
            PositionedDirectional(
              bottom: 6.r,
              end: -4.r,
              child: ConstrainedBox(
                // From the hero's end edge to the screen's start margin.
                constraints: BoxConstraints(
                  maxWidth: math.max(
                    0.0,
                    circle + (maxWidth - circle) / 2 - 4.r,
                  ),
                ),
                child: _Badge(text: badge, icon: badgeIcon),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon});

  final HayyaIconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = 148.r;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(44.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x470D5C52),
            offset: Offset(0, 18),
            blurRadius: 40,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The star of the brand mark, in gold.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(10.r),
              child: Opacity(
                opacity: 0.55,
                child: SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 84 84" '
                  'fill="none" stroke="#000" stroke-width="1.4">'
                  '<path d="M42 8 76 42 42 76 8 42Z M18 18h48v48H18z"/></svg>',
                  colorFilter: ColorFilter.mode(c.gold, BlendMode.srcIn),
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          if (icon case final icon?)
            HayyaIcon(icon, size: 64, color: c.onPrimary, strokeWidth: 1.6)
          else
            // A logo: it doesn't follow the system text size.
            ExcludeSemantics(
              child: Text(
                LocaleKeys.brand_mark.tr(),
                textDirection: TextDirection.rtl,
                textScaler: TextScaler.noScaling,
                style: context.type
                    .arabic(52, FontWeight.w800, height: 1)
                    .copyWith(color: c.onPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.icon});

  final String text;
  final HayyaIconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 14.r,
        vertical: 10.r,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10.r,
        children: [
          if (icon case final icon?)
            Container(
              width: 28.r,
              height: 28.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.goldSoft,
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: HayyaIcon(
                icon,
                size: 16,
                color: c.goldInk,
                strokeWidth: 2,
              ),
            ),
          Flexible(
            child: Text(
              text,
              style: context.type
                  .style(13, FontWeight.w700)
                  .copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}
