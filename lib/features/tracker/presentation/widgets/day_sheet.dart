import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/prayer_display.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/tracker_data.dart';
import '../../domain/entities/tracking_position.dart';
import '../cubit/tracker_cubit.dart';
import 'tracker_sheet.dart';

/// Edits the prayers of [day], with arrows to the days around it from
/// [firstDay] to today. Changes save as they're made.
///
/// On today only the prayers that have begun can be ticked.
Future<void> showDaySheet(
  BuildContext context, {
  required DateTime day,
  required TrackingPosition position,
  required DateTime firstDay,
}) {
  final cubit = context.read<TrackerCubit>();
  return showTrackerSheet(
    context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _DaySheet(day: day, position: position, firstDay: firstDay),
    ),
  );
}

class _DaySheet extends StatefulWidget {
  const _DaySheet({
    required this.day,
    required this.position,
    required this.firstDay,
  });

  final DateTime day;
  final TrackingPosition position;
  final DateTime firstDay;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late DateTime _day = widget.day.dateOnly;

  DateTime get _today => widget.position.day;

  @override
  Widget build(BuildContext context) {
    final format = context.format;
    final cubit = context.read<TrackerCubit>();
    final data = context.watch<TrackerCubit>().state;
    final prayed = data.prayedOn(_day);
    final isToday = _day == _today;
    // How many of the day's prayers can be ticked; all of them on past
    // days, and on today those that have begun (all if unknown).
    final open = isToday
        ? widget.position.due ?? trackedPrayers.length
        : trackedPrayers.length;

    final String subtitle;
    if (!data.isKnown(_day)) {
      subtitle = LocaleKeys.tracker_day_unknown.tr();
    } else {
      subtitle = LocaleKeys.tracker_day_prayed.tr(
        args: [
          format.number(prayed.length),
          format.number(trackedPrayers.length),
        ],
      );
    }

    return TrackerSheetFrame(
      title: format.gregorianDate(_day),
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArrowButton(
            icon: HayyaIcons.back,
            label: LocaleKeys.tracker_previous_day.tr(),
            onTap: _day.isAfter(widget.firstDay)
                ? () => setState(() => _day = _day.addDays(-1))
                : null,
          ),
          _ArrowButton(
            icon: HayyaIcons.chevron,
            label: LocaleKeys.tracker_next_day.tr(),
            onTap: _day.isBefore(_today)
                ? () => setState(() => _day = _day.addDays(1))
                : null,
          ),
        ],
      ),
      footer: HayyaButton(
        label: LocaleKeys.tracker_done.tr(),
        variant: HayyaButtonVariant.soft,
        expand: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: [
        for (final (i, prayer) in trackedPrayers.indexed)
          _DayPrayerRow(
            prayer: prayer,
            prayed: prayed.contains(prayer),
            onChanged: i < open || prayed.contains(prayer)
                ? (value) => cubit.setPrayed(_day, prayer, prayed: value)
                : null,
          ),
        if (open < trackedPrayers.length)
          Padding(
            padding: EdgeInsetsDirectional.only(top: 4.r),
            child: Text(
              LocaleKeys.tracker_day_not_started.tr(),
              textAlign: TextAlign.center,
              style: context.type
                  .style(12.5, FontWeight.w600)
                  .copyWith(color: context.colors.muted),
            ),
          ),
      ],
    );
  }
}

class _DayPrayerRow extends StatelessWidget {
  const _DayPrayerRow({
    required this.prayer,
    required this.prayed,
    required this.onChanged,
  });

  final Prayer prayer;
  final bool prayed;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;
    return Container(
      constraints: BoxConstraints(minHeight: 56.r),
      padding: EdgeInsetsDirectional.only(
        start: 12.r,
        end: 6.r,
        top: 4.r,
        bottom: 4.r,
      ),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(HayyaRadius.md),
      ),
      child: Row(
        spacing: 12.r,
        children: [
          HayyaIcon(prayer.icon, size: 20, color: enabled ? c.muted : c.faint),
          Expanded(
            child: Text(
              prayer.localizedName,
              style: context.type
                  .style(16, FontWeight.w700)
                  .copyWith(color: enabled ? c.text : c.faint),
            ),
          ),
          PrayedCheck(
            value: prayed,
            onChanged: onChanged,
            size: 26,
            semanticLabel: LocaleKeys.prayers_mark_prayed_for.tr(
              args: [prayer.localizedName],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.label, this.onTap});

  final HayyaIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: TapTarget(
        onTap: onTap,
        child: HayyaIcon(
          icon,
          size: 22,
          strokeWidth: 2.2,
          color: onTap == null ? c.faint : c.primaryInk,
        ),
      ),
    );
  }
}
