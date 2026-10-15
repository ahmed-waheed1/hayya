import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/hayya_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/localized_format.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/widgets.dart';
import '../../../generated/locale_keys.g.dart';
import '../../prayer_times/presentation/prayer_display.dart';
import '../domain/entities/tracker_data.dart';
import '../domain/entities/tracker_stats.dart';
import '../domain/entities/tracking_position.dart';
import '../domain/usecases/get_tracking_position.dart';
import 'cubit/tracker_cubit.dart';
import 'widgets/day_sheet.dart';
import 'widgets/missed_chart.dart';
import 'widgets/prayer_heatmap.dart';
import 'widgets/qada_card.dart';
import 'widgets/tracker_section.dart';

/// Streak, last-7-days completion, the heatmap, missed prayers by prayer
/// and the qada counter.
///
/// Phones get the design's single column. Wide tablets put the heatmap
/// and stats on the start side and the chart and qada on the end side;
/// the heatmap then shows as many weeks as fit.
///
/// Someone who hasn't marked a prayer yet sees a welcome card in place
/// of the stats and the chart.
class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final _getPosition = getIt<GetTrackingPosition>();
  Timer? _ticker;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Prayer times and midnight move "today" along.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Below this width two columns would be narrower than a phone's.
  static const _twoColumnsFrom = 760.0;

  /// A single column on a tablet stays about phone-width plus a margin.
  static const _singleColumnMaxWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    // Rebuild text when the language changes.
    context.locale;
    final position = _getPosition();
    final data = context.watch<TrackerCubit>().state;
    final stats = TrackerStats.compute(data, position);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = EdgeInsetsDirectional.fromSTEB(
              HayyaSpacing.s4,
              HayyaSpacing.s2,
              HayyaSpacing.s4,
              HayyaSpacing.s8,
            );
            final width = constraints.maxWidth - padding.horizontal;
            final gap = HayyaSpacing.s4;
            final twoColumns = constraints.isTablet && width >= _twoColumnsFrom;
            final columnWidth = twoColumns
                ? (width - HayyaSpacing.s6) / 2
                : constraints.isTablet
                ? width.clamp(0.0, _singleColumnMaxWidth)
                : width;
            // The heatmap card has 16 px padding on both sides.
            final weeks = PrayerHeatmap.weeksFor(columnWidth - 32.r);

            final parts = _Parts(
              data: data,
              stats: stats,
              position: position,
              weeks: weeks,
            );
            final header = _Header(weeks: weeks);

            if (twoColumns) {
              return SingleChildScrollView(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: gap,
                  children: [
                    header,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: HayyaSpacing.s6,
                      children: [
                        Expanded(
                          child: _Column(
                            spacing: gap,
                            children: parts.start(context),
                          ),
                        ),
                        Expanded(
                          child: _Column(
                            spacing: gap,
                            children: parts.end(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: padding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: columnWidth),
                  child: _Column(
                    spacing: gap,
                    children: [
                      header,
                      ...parts.start(context),
                      ...parts.end(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.spacing, required this.children});

  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: spacing,
    children: children,
  );
}

/// The screen's cards, split into the two tablet columns.
class _Parts {
  const _Parts({
    required this.data,
    required this.stats,
    required this.position,
    required this.weeks,
  });

  final TrackerData data;
  final TrackerStats stats;
  final TrackingPosition position;
  final int weeks;

  bool get _isNew => data.hasNoPrayers;

  List<Widget> start(BuildContext context) => [
    if (_isNew) const _Welcome() else _StatTiles(stats: stats),
    _HeatmapCard(data: data, position: position, weeks: weeks),
  ];

  List<Widget> end(BuildContext context) => [
    if (!_isNew) _MissedCard(stats: stats),
    const QadaCard(),
  ];
}

class _Header extends StatelessWidget {
  const _Header({required this.weeks});

  final int weeks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HayyaSpacing.minTouchTarget),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: HayyaSpacing.s1),
        child: Row(
          spacing: HayyaSpacing.s3,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  LocaleKeys.tracker_title.tr(),
                  style: type
                      .style(26, FontWeight.w800)
                      .copyWith(color: c.text),
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(minHeight: 36.r),
              alignment: Alignment.center,
              padding: EdgeInsetsDirectional.symmetric(horizontal: 12.r),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                context.format.digits(
                  LocaleKeys.tracker_range_weeks.plural(weeks),
                ),
                style: type.style(13, FontWeight.w700).copyWith(color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.stats});

  final TrackerStats stats;

  @override
  Widget build(BuildContext context) {
    final format = context.format;
    final percent = stats.weekPercent;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s3,
        children: [
          Expanded(
            child: StatTile(
              icon: HayyaIcons.streak,
              tone: StatTone.gold,
              label: LocaleKeys.tracker_current_streak.tr(),
              value: format.number(stats.streak),
              unit: LocaleKeys.tracker_days.plural(stats.streak),
            ),
          ),
          Expanded(
            child: StatTile(
              icon: HayyaIcons.tracker,
              label: format.digits(
                LocaleKeys.tracker_last_days.plural(TrackerStats.weekDays),
              ),
              value: percent == null
                  ? LocaleKeys.tracker_no_value.tr()
                  : LocaleKeys.tracker_percent.tr(
                      args: [format.number(percent)],
                    ),
              unit: percent == null
                  ? null
                  : LocaleKeys.tracker_week_fraction.tr(
                      args: [
                        format.number(stats.weekPrayed),
                        format.number(stats.weekPossible),
                      ],
                    ),
              progress: percent == null ? null : percent / 100,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({
    required this.data,
    required this.position,
    required this.weeks,
  });

  final TrackerData data;
  final TrackingPosition position;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final format = context.format;
    final firstDay = PrayerHeatmap.firstDay(position.day, weeks);
    void openDay(DateTime day) =>
        showDaySheet(context, day: day, position: position, firstDay: firstDay);
    final legendStyle = context.type
        .style(11.5, FontWeight.w600)
        .copyWith(color: c.muted);

    return TrackerSection(
      title: LocaleKeys.tracker_heatmap_title.tr(),
      caption: LocaleKeys.tracker_heatmap_scale.tr(
        args: [format.number(0), format.number(trackedPrayers.length)],
      ),
      spacing: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8.r,
        children: [
          // The cells are too small to reach one by one with a screen
          // reader; it opens today instead, and the sheet's arrows go back.
          Semantics(
            label: LocaleKeys.tracker_heatmap_label.tr(
              args: [
                format.digits(LocaleKeys.tracker_range_weeks.plural(weeks)),
              ],
            ),
            hint: LocaleKeys.tracker_heatmap_hint.tr(),
            button: true,
            onTap: () => openDay(position.day),
            child: ExcludeSemantics(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: PrayerHeatmap(
                  data: data,
                  today: position.day,
                  weeks: weeks,
                  onDayTap: openDay,
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 4.r,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 4.r),
                  child: Text(LocaleKeys.tracker_less.tr(), style: legendStyle),
                ),
                for (final color in c.heatmap)
                  Container(
                    width: 13.r,
                    height: 13.r,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 4.r),
                  child: Text(LocaleKeys.tracker_more.tr(), style: legendStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedCard extends StatelessWidget {
  const _MissedCard({required this.stats});

  final TrackerStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final format = context.format;
    final window = format.digits(
      LocaleKeys.tracker_last_days.plural(TrackerStats.missedWindow),
    );
    final most = stats.mostMissed;

    return TrackerSection(
      title: LocaleKeys.tracker_missed_title.tr(),
      caption: window,
      child: stats.missedDays == 0
          ? Text(
              LocaleKeys.tracker_missed_empty.tr(),
              style: context.type
                  .style(14, FontWeight.w600)
                  .copyWith(color: c.muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12.r,
              children: [
                Semantics(
                  label: MissedChart.semanticsLabel(
                    stats.missed,
                    window,
                    format,
                  ),
                  child: ExcludeSemantics(
                    child: MissedChart(missed: stats.missed),
                  ),
                ),
                if (most.isEmpty)
                  TrackerNote(
                    icon: HayyaIcons.check,
                    text: LocaleKeys.tracker_missed_none.tr(),
                    background: c.primarySoft,
                    foreground: c.primaryInk,
                  )
                else
                  TrackerNote(
                    icon: HayyaIcons.insight,
                    text: LocaleKeys.tracker_missed_insight.tr(
                      args: [most.first.localizedName],
                    ),
                    background: c.goldSoft,
                    foreground: c.goldInk,
                  ),
              ],
            ),
    );
  }
}

/// For someone who hasn't marked a prayer yet.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return HayyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.r,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: HayyaIcon(HayyaIcons.tracker, size: 22, color: c.primaryInk),
          ),
          Semantics(
            header: true,
            child: Text(
              LocaleKeys.tracker_welcome_title.tr(),
              style: type.style(18, FontWeight.w800).copyWith(color: c.text),
            ),
          ),
          Text(
            LocaleKeys.tracker_welcome_body.tr(),
            style: type.style(14, FontWeight.w600).copyWith(color: c.muted),
          ),
          SizedBox(height: 2.r),
          HayyaButton(
            label: LocaleKeys.tracker_welcome_action.tr(),
            variant: HayyaButtonVariant.soft,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
