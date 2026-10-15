import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../prayer_display.dart';

/// Today's six times as [PrayerRow]s, the current one highlighted.
///
/// Phone: the rows in a [PrayerRowGroup] (the "Today" title sits above it).
/// Tablet: a full-height card with the title inside and larger rows.
///
/// Adhan bells and prayed checks are display-only until notifications and
/// the tracker exist.
class PrayerList extends StatelessWidget {
  const PrayerList({super.key, required this.schedule, this.tablet = false});

  final PrayerSchedule schedule;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);

    Widget row(PrayerTime entry) {
      final prayer = entry.prayer;
      final clock = LocalizedFormat.clock(
        entry.time,
        locale,
        use24Hour: use24Hour,
      );
      return PrayerRow(
        icon: prayer.icon,
        name: prayer.localizedName,
        time: clock.time,
        meridiem: clock.meridiem,
        adhanOn: prayer.isObligatory,
        onToggleAdhan: null,
        isCurrent: prayer == schedule.current.prayer,
        trackable: prayer.isObligatory,
        large: tablet,
      );
    }

    final rows = schedule.today.times.map(row).toList();
    if (!tablet) return PrayerRowGroup(children: rows);

    return HayyaCard(
      radius: HayyaRadius.xxl,
      padding: EdgeInsetsDirectional.fromSTEB(20.r, 24.r, 20.r, 20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s2,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              HayyaSpacing.s2,
              0,
              HayyaSpacing.s2,
              HayyaSpacing.s2,
            ),
            child: Text(
              LocaleKeys.home_today.tr(),
              style: context.type
                  .style(22, FontWeight.w800)
                  .copyWith(color: context.colors.text),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}
