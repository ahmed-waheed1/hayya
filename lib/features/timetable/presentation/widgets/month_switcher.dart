import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';

/// The month card: previous, the month with the Hijri months it spans,
/// next.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.hijriRange,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final String month;
  final String hijriRange;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HayyaCard(
      radius: 18.r,
      padding: EdgeInsetsDirectional.all(6.r),
      child: Row(
        spacing: HayyaSpacing.s2,
        children: [
          SquareIconButton(
            icon: HayyaIcons.back,
            label: previousLabel,
            onTap: onPrevious,
            filled: true,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(
                children: [
                  Text(
                    month,
                    textAlign: TextAlign.center,
                    style: context.type
                        .style(17, FontWeight.w800)
                        .copyWith(color: c.text),
                  ),
                  Text(
                    hijriRange,
                    textAlign: TextAlign.center,
                    style: context.type
                        .style(12.5, FontWeight.w600)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
          ),
          SquareIconButton(
            icon: HayyaIcons.chevron,
            label: nextLabel,
            onTap: onNext,
            filled: true,
          ),
        ],
      ),
    );
  }
}

/// A 44 × 44 icon button: back on the title row, previous/next on a
/// [surface2] fill in the month card.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final HayyaIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular((filled ? 12 : 14).r);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled ? c.surface2 : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: math.max(HayyaSpacing.minTouchTarget, 44.r),
            child: Center(
              child: HayyaIcon(
                icon,
                size: filled ? 20 : 22,
                strokeWidth: filled ? 2.2 : 2,
                color: c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
