import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/qibla_direction.dart';
import '../qibla_display.dart';

/// The two cards under the dial: Qibla direction and distance to Mecca.
class QiblaStats extends StatelessWidget {
  const QiblaStats({
    super.key,
    required this.bearing,
    required this.distanceKm,
  });

  final double bearing;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final format = context.format;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s3,
        children: [
          Expanded(
            child: _StatCard(
              label: LocaleKeys.qibla_direction_label.tr(),
              value: format.degrees(bearing),
              valueColor: c.primaryInk,
              sub: LocaleKeys.qibla_direction_sub.tr(
                args: [compassPoint(bearing).label],
              ),
            ),
          ),
          Expanded(
            child: _StatCard(
              label: LocaleKeys.qibla_distance_label.tr(),
              value: format.distanceKm(distanceKm),
              valueColor: c.text,
              sub: LocaleKeys.qibla_distance_sub.tr(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sub,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Semantics(
      container: true,
      child: HayyaCard(
        padding: EdgeInsetsDirectional.all(HayyaSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: HayyaSpacing.s1,
          children: [
            Text(
              label,
              style: type.style(13, FontWeight.w700).copyWith(color: c.muted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: type
                    .style(26, FontWeight.w800, tabular: true, height: 1.25)
                    .copyWith(color: valueColor),
              ),
            ),
            Text(
              sub,
              style: type.style(12.5, FontWeight.w600).copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
