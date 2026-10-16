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
///
/// Side by side when both fit their value and their longest word;
/// otherwise (large text) one above the other.
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
    final cards = [
      _StatCard(
        label: LocaleKeys.qibla_direction_label.tr(),
        value: format.degrees(bearing),
        valueColor: c.primaryInk,
        sub: LocaleKeys.qibla_direction_sub.tr(
          args: [compassPoint(bearing).label],
        ),
      ),
      _StatCard(
        label: LocaleKeys.qibla_distance_label.tr(),
        value: format.distanceKm(distanceKm),
        valueColor: c.text,
        sub: LocaleKeys.qibla_distance_sub.tr(),
      ),
    ];
    final gap = HayyaSpacing.s3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - gap) / 2;
        if (cards.every((card) => card.minWidth(context) <= half)) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [for (final card in cards) Expanded(child: card)],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: cards,
        );
      },
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

  TextStyle _labelStyle(BuildContext context) =>
      context.type.style(13, FontWeight.w700);
  TextStyle _valueStyle(BuildContext context) =>
      context.type.style(26, FontWeight.w800, tabular: true, height: 1.25);
  TextStyle _subStyle(BuildContext context) =>
      context.type.style(12.5, FontWeight.w600);

  /// The narrowest this card can be with its value on one line and no
  /// word broken.
  double minWidth(BuildContext context) {
    double measure(String text, TextStyle style, {bool whole = false}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: whole ? 1 : null,
      )..layout();
      final width = whole ? painter.width : painter.minIntrinsicWidth;
      painter.dispose();
      return width;
    }

    return [
          measure(label, _labelStyle(context)),
          measure(value, _valueStyle(context), whole: true),
          measure(sub, _subStyle(context)),
        ].reduce((a, b) => a > b ? a : b) +
        2 * HayyaSpacing.s4 +
        1;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      child: HayyaCard(
        padding: EdgeInsetsDirectional.all(HayyaSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: HayyaSpacing.s1,
          children: [
            Text(label, style: _labelStyle(context).copyWith(color: c.muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: _valueStyle(context).copyWith(color: valueColor),
              ),
            ),
            Text(sub, style: _subStyle(context).copyWith(color: c.muted)),
          ],
        ),
      ),
    );
  }
}
