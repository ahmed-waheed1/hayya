import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_colors.dart';
import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';

/// Time-of-day header: period gradient with the geometric pattern, the
/// city chip and both dates. Fills the space its parent gives it.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.period,
    required this.periodIcon,
    required this.city,
    required this.gregorianDate,
    required this.hijriDate,
    required this.locating,
    required this.onCityTap,
    this.qiblaLabel,
    this.onQiblaTap,
    this.tablet = false,
  });

  final PrayerPeriod period;

  /// The current prayer's icon, shown at the end on phones.
  final HayyaIconData periodIcon;
  final String city;
  final String gregorianDate;
  final String hijriDate;

  /// Shows a spinner in the city chip while a fresh fix is found.
  final bool locating;
  final VoidCallback onCityTap;

  /// Tablet only: "Qibla 136° SE" chip at the end.
  final String? qiblaLabel;
  final VoidCallback? onQiblaTap;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final palette = context.colors.periods[period]!;
    final ink = palette.ink;
    final lightInk = ink.computeLuminance() > 0.5;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightInk ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.gradient),
        child: CustomPaint(
          painter: HeaderPatternPainter(
            color: palette.pattern.withValues(
              alpha: period == PrayerPeriod.dhuhr && !context.isDark
                  ? 0.09
                  : 0.08,
            ),
            tile: (tablet ? 64 : 56).r,
            stars: period == PrayerPeriod.isha,
            starColor: ink,
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: ink),
            child: IconTheme.merge(
              data: IconThemeData(color: ink),
              child: tablet
                  ? _tabletContent(context, palette)
                  : _phoneContent(context, palette),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneContent(BuildContext context, PeriodPalette palette) {
    final type = context.type;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.paddingOf(context).top + HayyaSpacing.s2,
        start: HayyaSpacing.screenGutter,
        end: HayyaSpacing.screenGutter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: HayyaSpacing.s3,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _Chip(
                    color: palette.chip,
                    onTap: onCityTap,
                    semanticHint: LocaleKeys.home_update_location.tr(),
                    padding: EdgeInsetsDirectional.only(start: 10.r, end: 14.r),
                    leading: _CityIcon(locating: locating, size: 20),
                    label: city,
                    style: type.style(17, FontWeight.w800),
                  ),
                ),
              ),
              Opacity(
                opacity: 0.85,
                child: HayyaIcon(
                  periodIcon,
                  size: 30,
                  color: palette.ink,
                  strokeWidth: 1.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.r),
          Padding(
            padding: EdgeInsetsDirectional.only(start: HayyaSpacing.s1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.r,
              children: [
                Text(
                  gregorianDate,
                  style: type.style(15, FontWeight.w700, height: 1.5),
                ),
                Opacity(
                  opacity: 0.85,
                  child: Row(
                    spacing: 6.r,
                    children: [
                      HayyaIcon(
                        HayyaIcons.theme,
                        size: 14,
                        color: palette.ink,
                        strokeWidth: 2,
                      ),
                      Flexible(
                        child: Text(
                          hijriDate,
                          style: type.style(14, FontWeight.w600, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabletContent(BuildContext context, PeriodPalette palette) {
    final type = context.type;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.paddingOf(context).top + 40.r,
        start: 40.r,
        end: 40.r,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HayyaSpacing.s6,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Chip(
                  color: palette.chip,
                  onTap: onCityTap,
                  semanticHint: LocaleKeys.home_update_location.tr(),
                  padding: EdgeInsetsDirectional.only(start: 10.r, end: 14.r),
                  leading: _CityIcon(locating: locating, size: 22),
                  label: city,
                  style: type.style(20, FontWeight.w800),
                ),
                SizedBox(height: 12.r),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: HayyaSpacing.s1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: HayyaSpacing.s1,
                    children: [
                      Text(
                        gregorianDate,
                        style: type.style(17, FontWeight.w700),
                      ),
                      Opacity(
                        opacity: 0.85,
                        child: Text(
                          hijriDate,
                          style: type.style(15, FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (qiblaLabel != null)
            _Chip(
              color: palette.chip,
              onTap: onQiblaTap,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: HayyaSpacing.s4,
              ),
              leading: HayyaIcon(
                HayyaIcons.qibla,
                size: 20,
                color: palette.ink,
                strokeWidth: 1.9,
              ),
              label: qiblaLabel!,
              style: type.style(15, FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

/// Translucent 44 px pill on the header gradient.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.color,
    required this.onTap,
    required this.padding,
    required this.leading,
    required this.label,
    required this.style,
    this.semanticHint,
  });

  final Color color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget leading;
  final String label;
  final TextStyle style;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HayyaRadius.md);
    return Semantics(
      button: true,
      hint: semanticHint,
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            constraints: BoxConstraints(
              minHeight: math.max(44.r, HayyaSpacing.minTouchTarget),
            ),
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: HayyaSpacing.s2,
              children: [
                leading,
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CityIcon extends StatelessWidget {
  const _CityIcon({required this.locating, required this.size});

  final bool locating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    if (!locating) {
      return HayyaIcon(
        HayyaIcons.location,
        size: size,
        color: color,
        strokeWidth: 2,
      );
    }
    return SizedBox.square(
      dimension: size.r,
      child: Padding(
        padding: EdgeInsetsDirectional.all(2.r),
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      ),
    );
  }
}

/// The header's repeating diamond-in-square pattern, plus a few stars at
/// night. Star positions are fractions of the phone header (390 × 252).
class HeaderPatternPainter extends CustomPainter {
  const HeaderPatternPainter({
    required this.color,
    required this.tile,
    this.stars = false,
    this.starColor = Colors.transparent,
  });

  final Color color;
  final double tile;
  final bool stars;

  /// The white stars; the night header passes its ink.
  final Color starColor;

  static const _stars = [
    (40.0, 30.0, 1.2, 0.8),
    (120.0, 22.0, 0.9, 0.6),
    (300.0, 40.0, 1.4, 0.85),
    (352.0, 98.0, 1.0, 0.6),
    (210.0, 64.0, 0.8, 0.5),
    (72.0, 176.0, 1.0, 0.5),
    (330.0, 200.0, 0.9, 0.5),
  ];

  /// The one gold star; the night header is dark in both themes.
  static const _goldStar = (250.0, 150.0, 1.1, 0.8);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final u = tile / 56;
    final path = Path()
      ..moveTo(28 * u, 10 * u)
      ..lineTo(46 * u, 28 * u)
      ..lineTo(28 * u, 46 * u)
      ..lineTo(10 * u, 28 * u)
      ..close()
      ..addRect(Rect.fromLTWH(15 * u, 15 * u, 26 * u, 26 * u))
      ..moveTo(0, 28 * u)
      ..lineTo(10 * u, 28 * u)
      ..moveTo(46 * u, 28 * u)
      ..lineTo(56 * u, 28 * u)
      ..moveTo(28 * u, 0)
      ..lineTo(28 * u, 10 * u)
      ..moveTo(28 * u, 46 * u)
      ..lineTo(28 * u, 56 * u);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        canvas.drawPath(path.shift(Offset(x, y)), paint);
      }
    }
    canvas.restore();

    if (!stars) return;
    final sx = size.width / 390;
    final sy = size.height / 252;
    void star((double, double, double, double) s, Color c) {
      final (x, y, r, opacity) = s;
      canvas.drawCircle(
        Offset(x * sx, y * sy),
        r * u,
        Paint()..color = c.withValues(alpha: opacity),
      );
    }

    for (final s in _stars) {
      star(s, starColor);
    }
    star(_goldStar, HayyaColors.dark.goldInk);
  }

  @override
  bool shouldRepaint(HeaderPatternPainter old) =>
      old.color != color ||
      old.tile != tile ||
      old.stars != stars ||
      old.starColor != starColor;
}
