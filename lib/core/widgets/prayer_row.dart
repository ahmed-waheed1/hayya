import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../generated/locale_keys.g.dart';
import '../theme/hayya_radius.dart';
import '../theme/hayya_spacing.dart';
import '../theme/theme_context.dart';
import 'adhan_toggle.dart';
import 'hayya_card.dart';
import 'hayya_icon.dart';
import 'prayed_check.dart';

/// One prayer in the day list: icon, name, time, adhan bell, prayed check.
///
/// - [isCurrent] highlights the row and adds the NOW badge.
/// - [trackable] false is the Sunrise style: muted, gold icon, no check.
/// - [large] is the tablet size: 76 px rows with bigger type.
class PrayerRow extends StatelessWidget {
  const PrayerRow({
    super.key,
    required this.icon,
    required this.name,
    required this.time,
    required this.meridiem,
    required this.adhanOn,
    required this.onToggleAdhan,
    this.prayed = false,
    this.onTogglePrayed,
    this.isCurrent = false,
    this.trackable = true,
    this.large = false,
  });

  final HayyaIconData icon;
  final String name;

  /// Already formatted for the user's locale and numeral setting, e.g. "5:28".
  final String time;

  /// AM/PM marker for the locale ("AM", "ص"); empty for 24-hour clocks.
  final String meridiem;

  final bool adhanOn;
  final ValueChanged<bool>? onToggleAdhan;
  final bool prayed;
  final ValueChanged<bool>? onTogglePrayed;
  final bool isCurrent;
  final bool trackable;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final m = large ? _RowMetrics.large : _RowMetrics.regular;

    final (Color tileBg, Color tileFg) = isCurrent
        ? (c.primary, c.onPrimary)
        : trackable
        ? (c.surface2, c.muted)
        : (c.goldSoft, c.goldInk);
    final (Color ink, Color meridiemInk, FontWeight weight) = isCurrent
        ? (c.primaryInk, c.primaryInk, FontWeight.w800)
        : trackable
        ? (c.text, c.muted, FontWeight.w700)
        : (c.muted, c.muted, FontWeight.w600);

    final nameText = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: type.style(m.name, weight).copyWith(color: ink),
    );

    return Container(
      height: large ? 76.r : HayyaSpacing.listRowHeight,
      padding: EdgeInsetsDirectional.only(start: m.start.r, end: m.end.r),
      decoration: BoxDecoration(
        color: isCurrent ? c.primarySoft : null,
        borderRadius: BorderRadius.circular(HayyaRadius.md),
      ),
      child: Row(
        spacing: m.gap.r,
        children: [
          Container(
            width: m.tile.r,
            height: m.tile.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(m.tileRadius.r),
            ),
            child: HayyaIcon(icon, size: m.icon, color: tileFg),
          ),
          // NOW sits under the name, not beside it: inline, the current row
          // needs 336–376 px and a phone row is ~338 px.
          Expanded(
            child: isCurrent
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2.r,
                    children: [
                      nameText,
                      _NowBadge(fontSize: m.badge),
                    ],
                  )
                : nameText,
          ),
          // Capped and scaled down rather than squeezing the name to nothing
          // under large accessibility text sizes.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: m.timeMaxWidth.r),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: time,
                  children: [
                    if (meridiem.isNotEmpty)
                      TextSpan(
                        text: ' $meridiem',
                        style: type
                            .style(m.meridiem, weight)
                            .copyWith(color: meridiemInk),
                      ),
                  ],
                ),
                style: type
                    .style(m.time, weight, tabular: true)
                    .copyWith(color: ink),
              ),
            ),
          ),
          AdhanToggle(
            value: adhanOn,
            onChanged: onToggleAdhan,
            filled: false,
            iconSize: m.bell,
            semanticLabel: LocaleKeys.prayers_adhan_for.tr(args: [name]),
          ),
          if (trackable)
            PrayedCheck(
              value: prayed,
              onChanged: onTogglePrayed,
              size: m.check,
              outlineColor: isCurrent ? c.primaryInk : null,
              semanticLabel: LocaleKeys.prayers_mark_prayed_for.tr(
                args: [name],
              ),
            )
          else
            SizedBox.square(
              dimension: 44.r,
              child: Center(
                child: Container(width: 12.r, height: 2, color: c.faint),
              ),
            ),
        ],
      ),
    );
  }
}

/// White surface holding a day's [PrayerRow]s.
class PrayerRowGroup extends StatelessWidget {
  const PrayerRowGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return HayyaCard(
      padding: EdgeInsetsDirectional.all(6.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2.r,
        children: children,
      ),
    );
  }
}

/// Design sizes for [PrayerRow] (phone) and its tablet variant.
class _RowMetrics {
  const _RowMetrics({
    required this.start,
    required this.end,
    required this.gap,
    required this.tile,
    required this.tileRadius,
    required this.icon,
    required this.name,
    required this.badge,
    required this.time,
    required this.meridiem,
    required this.timeMaxWidth,
    required this.bell,
    required this.check,
  });

  final double start, end, gap, tile, tileRadius, icon, name, badge;
  final double time, meridiem, timeMaxWidth, bell, check;

  static const regular = _RowMetrics(
    start: 12,
    end: 6,
    gap: 12,
    tile: 34,
    tileRadius: 11,
    icon: 20,
    name: 16,
    badge: 11,
    time: 17,
    meridiem: 12,
    timeMaxWidth: 88,
    bell: 21,
    check: 26,
  );

  static const large = _RowMetrics(
    start: 16,
    end: 8,
    gap: 16,
    tile: 46,
    tileRadius: 14,
    icon: 24,
    name: 20,
    badge: 12,
    time: 24,
    meridiem: 14,
    timeMaxWidth: 124,
    bell: 23,
    check: 28,
  );
}

class _NowBadge extends StatelessWidget {
  const _NowBadge({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 6.r, vertical: 1.r),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(HayyaRadius.full),
      ),
      child: Text(
        LocaleKeys.prayers_now.tr(),
        style: context.type
            .style(fontSize, FontWeight.w800, trackingEm: 0.06)
            .copyWith(color: c.onPrimary),
      ),
    );
  }
}
