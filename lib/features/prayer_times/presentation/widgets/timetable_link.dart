import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';

/// "Monthly timetable" beside Home's "Today" title: a text link with a
/// chevron on phones, a tinted button on tablets.
class TimetableLink extends StatelessWidget {
  const TimetableLink({super.key, this.tablet = false});

  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(14.r);
    final label = Text(
      LocaleKeys.timetable_title.tr(),
      style: context.type.label.copyWith(color: c.primaryInk),
    );

    return Semantics(
      link: true,
      child: Material(
        color: tablet ? c.primarySoft : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: () => context.go(AppRoutes.timetable),
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(HayyaSpacing.minTouchTarget, 44.r),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tablet ? 14.r : HayyaSpacing.s1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: (tablet ? 8 : 6).r,
                children: [
                  HayyaIcon(
                    HayyaIcons.timetable,
                    size: 18,
                    strokeWidth: 1.9,
                    color: c.primaryInk,
                  ),
                  Flexible(child: label),
                  if (!tablet)
                    HayyaIcon(
                      HayyaIcons.chevron,
                      size: 16,
                      strokeWidth: 2.2,
                      color: c.primaryInk,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
