import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../notifications/domain/entities/adhan_preferences.dart';
import '../../../notifications/presentation/cubit/adhan_notifications_cubit.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../prayer_display.dart';

/// Today's six times as [PrayerRow]s, the current one highlighted.
///
/// Phone: the rows in a [PrayerRowGroup] (the "Today" title sits above it).
/// Tablet: a full-height card with the title inside and larger rows.
///
/// The bells switch each prayer's adhan notification. Prayed checks are
/// display-only until the tracker exists.
class PrayerList extends StatelessWidget {
  const PrayerList({super.key, required this.schedule, this.tablet = false});

  final PrayerSchedule schedule;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final format = context.format;
    final adhan = context.select<AdhanNotificationsCubit, AdhanPreferences>(
      (cubit) => cubit.state.preferences,
    );
    final notifications = context.read<AdhanNotificationsCubit>();

    Widget row(PrayerTime entry) {
      final prayer = entry.prayer;
      final clock = format.clock(entry.time);
      return PrayerRow(
        icon: prayer.icon,
        name: prayer.localizedName,
        time: clock.time,
        meridiem: clock.meridiem,
        adhanOn: adhan.isEnabled(prayer),
        // Sunrise has no adhan.
        onToggleAdhan: prayer.isObligatory
            ? (on) => notifications.setAdhan(prayer, on: on)
            : null,
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
