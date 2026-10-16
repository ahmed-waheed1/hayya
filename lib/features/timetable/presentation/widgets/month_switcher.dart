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
