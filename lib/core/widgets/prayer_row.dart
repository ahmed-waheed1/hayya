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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;

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
      style: type.style(16, weight).copyWith(color: ink),
    );

    return Container(
      height: HayyaSpacing.listRowHeight,
      padding: EdgeInsetsDirectional.only(start: 12.r, end: 6.r),
      decoration: BoxDecoration(
        color: isCurrent ? c.primarySoft : null,
        borderRadius: BorderRadius.circular(HayyaRadius.md),
      ),
      child: Row(
        spacing: HayyaSpacing.s3,
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: HayyaIcon(icon, size: 20, color: tileFg),
          ),
          // NOW sits under the name, not beside it: inline, the current row
          // needs 336–376 px and a phone row is ~338 px.
          Expanded(
            child: isCurrent
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2.r,
                    children: [nameText, const _NowBadge()],
                  )
                : nameText,
          ),
          // Capped and scaled down rather than squeezing the name to nothing
          // under large accessibility text sizes.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 88.r),
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
                            .style(12, weight)
                            .copyWith(color: meridiemInk),
                      ),
                  ],
                ),
                style: type
                    .style(17, weight, tabular: true)
                    .copyWith(color: ink),
              ),
            ),
          ),
          AdhanToggle(
            value: adhanOn,
            onChanged: onToggleAdhan,
            filled: false,
            iconSize: 21,
            semanticLabel: LocaleKeys.prayers_adhan_for.tr(args: [name]),
          ),
          if (trackable)
            PrayedCheck(
              value: prayed,
              onChanged: onTogglePrayed,
              size: 26,
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

class _NowBadge extends StatelessWidget {
  const _NowBadge();

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
            .style(11, FontWeight.w800, trackingEm: 0.06)
            .copyWith(color: c.onPrimary),
      ),
    );
  }
}
