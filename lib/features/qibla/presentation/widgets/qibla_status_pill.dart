import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../cubit/qibla_state.dart';

/// The pill above the dial: which way to turn, aligned, or why the compass
/// can't help.
class QiblaStatusPill extends StatelessWidget {
  const QiblaStatusPill({super.key, required this.state});

  final QiblaReady state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final format = context.format;
    final turn = state.turn;

    final (
      Color bg,
      Color ink,
      HayyaIconData icon,
      String text,
      bool flip,
    ) = switch (state.compass) {
      CompassStatus.checking => (
        c.surface2,
        c.muted,
        HayyaIcons.qibla,
        LocaleKeys.qibla_checking.tr(),
        false,
      ),
      CompassStatus.calibrating => (
        c.goldSoft,
        c.goldInk,
        HayyaIcons.calibrate,
        LocaleKeys.qibla_needs_calibration.tr(),
        false,
      ),
      CompassStatus.noSensor => (
        c.surface2,
        c.muted,
        HayyaIcons.compassOff,
        LocaleKeys.qibla_static_direction.tr(),
        false,
      ),
      CompassStatus.live when state.aligned => (
        c.primary,
        c.onPrimary,
        HayyaIcons.check,
        LocaleKeys.qibla_facing.tr(),
        false,
      ),
      CompassStatus.live => (
        c.goldSoft,
        c.goldInk,
        HayyaIcons.turn,
        (turn! < 0 ? LocaleKeys.qibla_turn_left : LocaleKeys.qibla_turn_right)
            .tr(args: [format.number(turn.abs().round())]),
        // Left and right are physical: flip by the turn, not the locale.
        turn < 0,
      ),
    };

    return Semantics(
      // Announce state changes, not every degree of a turn.
      liveRegion: state.compass != CompassStatus.live || state.aligned,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(minHeight: 40.r),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: HayyaSpacing.s4,
          vertical: HayyaSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(HayyaRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: HayyaSpacing.s2,
          children: [
            Transform.flip(
              flipX: flip,
              child: HayyaIcon(icon, size: 18, color: ink, strokeWidth: 2.2),
            ),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: context.type
                    .style(15, FontWeight.w800, tabular: true)
                    .copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
