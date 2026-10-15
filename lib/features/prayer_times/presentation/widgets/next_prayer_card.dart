import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../prayer_display.dart';
import 'countdown_ring.dart';

/// Hero card: the next prayer, its time and a live countdown ring.
///
/// Phone: text beside a 128 px ring. Tablet: a tall column around a
/// 240 px ring with the name and countdown inside it.
class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({
    super.key,
    required this.schedule,
    this.tablet = false,
  });

  final PrayerSchedule schedule;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final next = schedule.next;
    final name = next.prayer.localizedName;
    final clock = LocalizedFormat.clock(
      next.time,
      locale,
      use24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final countdown = LocalizedFormat.countdown(schedule.remaining, locale);
    final view = _NextPrayerView(
      name: name,
      tomorrow: schedule.nextIsTomorrow,
      time: clock.time,
      meridiem: clock.meridiem,
      countdown: countdown,
      progress: schedule.progress,
      ringLabel: LocaleKeys.home_countdown_label.tr(args: [name, countdown]),
    );
    return tablet ? _TabletCard(view) : _PhoneCard(view);
  }
}

class _NextPrayerView {
  const _NextPrayerView({
    required this.name,
    required this.tomorrow,
    required this.time,
    required this.meridiem,
    required this.countdown,
    required this.progress,
    required this.ringLabel,
  });

  final String name;
  final bool tomorrow;
  final String time;
  final String meridiem;
  final String countdown;
  final double progress;
  final String ringLabel;
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard(this.v);

  final _NextPrayerView v;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return HayyaCard(
      elevation: HayyaElevation.hero,
      radius: HayyaRadius.xxl,
      padding: EdgeInsetsDirectional.fromSTEB(20.r, 18.r, 18.r, 18.r),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 120.r),
        child: Row(
          spacing: 12.r,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4.r,
                children: [
                  Text(
                    LocaleKeys.prayers_next_prayer.tr(),
                    style: type.overline.copyWith(color: c.goldInk),
                  ),
                  Text.rich(
                    TextSpan(
                      text: v.name,
                      children: [
                        if (v.tomorrow)
                          TextSpan(
                            text: ' · ${LocaleKeys.home_tomorrow.tr()}',
                            style: type
                                .style(13, FontWeight.w700)
                                .copyWith(color: c.muted),
                          ),
                      ],
                    ),
                    style: type
                        .style(24, FontWeight.w800, height: 1.25)
                        .copyWith(color: c.primaryInk),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: _TimeText(
                      time: v.time,
                      meridiem: v.meridiem,
                      size: 36,
                      meridiemSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            CountdownRing(
              progress: v.progress,
              size: 128,
              stroke: 9,
              dotRadius: 6.5,
              dotStroke: 2.5,
              semanticLabel: v.ringLabel,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 2.r,
                children: [
                  _Countdown(v.countdown, size: 19),
                  Text(
                    LocaleKeys.home_remaining.tr(),
                    style: type
                        .style(12, FontWeight.w700)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletCard extends StatelessWidget {
  const _TabletCard(this.v);

  final _NextPrayerView v;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return HayyaCard(
      elevation: HayyaElevation.hero,
      radius: HayyaRadius.xxl,
      padding: EdgeInsetsDirectional.all(32.r),
      child: Column(
        spacing: 22.r,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              LocaleKeys.prayers_next_prayer.tr(),
              style: type.overline.copyWith(color: c.goldInk),
            ),
          ),
          CountdownRing(
            progress: v.progress,
            size: 240,
            stroke: 14,
            dotRadius: 10,
            dotStroke: 3.5,
            semanticLabel: v.ringLabel,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 28.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 4.r,
                children: [
                  Text(
                    v.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type
                        .style(30, FontWeight.w800, height: 1.2)
                        .copyWith(color: c.primaryInk),
                  ),
                  _Countdown(v.countdown, size: 32),
                  Text(
                    v.tomorrow
                        ? '${LocaleKeys.home_remaining.tr()} · '
                              '${LocaleKeys.home_tomorrow.tr()}'
                        : LocaleKeys.home_remaining.tr(),
                    style: type
                        .style(14, FontWeight.w700)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _TimeText(
              time: v.time,
              meridiem: v.meridiem,
              size: 52,
              meridiemSize: 20,
              trackingEm: -0.02,
            ),
          ),
        ],
      ),
    );
  }
}

/// "5:28 AM" with the marker smaller and muted.
class _TimeText extends StatelessWidget {
  const _TimeText({
    required this.time,
    required this.meridiem,
    required this.size,
    required this.meridiemSize,
    this.trackingEm = -0.01,
  });

  final String time;
  final String meridiem;
  final double size;
  final double meridiemSize;
  final double trackingEm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Text.rich(
      TextSpan(
        text: time,
        children: [
          if (meridiem.isNotEmpty)
            TextSpan(
              text: ' $meridiem',
              style: type
                  .style(meridiemSize, FontWeight.w700)
                  .copyWith(color: c.muted),
            ),
        ],
      ),
      maxLines: 1,
      style: type
          .style(
            size,
            FontWeight.w800,
            tabular: true,
            trackingEm: trackingEm,
            height: 1.15,
          )
          .copyWith(color: c.text),
    );
  }
}

/// HH:MM:SS, always left to right so the units read in order in Arabic.
class _Countdown extends StatelessWidget {
  const _Countdown(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      style: context.type
          .style(size, FontWeight.w800, tabular: true, trackingEm: -0.01)
          .copyWith(color: context.colors.text),
    );
  }
}
