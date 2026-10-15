import 'dart:math' as math;

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
import '../../../generated/locale_keys.g.dart';
import '../../qibla/domain/qibla_direction.dart';
import '../../qibla/presentation/qibla_display.dart';
import 'cubit/prayer_times_cubit.dart';
import 'cubit/prayer_times_state.dart';
import 'prayer_display.dart';
import 'widgets/home_header.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/location_status_view.dart';
import 'widgets/next_prayer_card.dart';
import 'widgets/overlap_layout.dart';
import 'widgets/prayer_list.dart';
import 'widgets/timetable_link.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PrayerTimesCubit>()..start(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the system settings, the permission or GPS may be on now.
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<PrayerTimesCubit>().recheck(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild text when the language changes.
    context.locale;
    return Scaffold(
      body: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
        builder: (context, state) => switch (state) {
          PrayerTimesLoading() => const _Loading(),
          PrayerTimesReady() => _Ready(state),
          PrayerTimesLocationError() => _LocationError(state),
        },
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready(this.state);

  final PrayerTimesReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerTimesCubit>();
    final locale = context.locale;
    final format = context.format;
    final schedule = state.schedule;
    final current = schedule.current.prayer;

    HomeHeader header({required bool tablet}) => HomeHeader(
      period: current.period,
      periodIcon: current.icon,
      city: state.location.cityName(locale),
      gregorianDate: format.gregorianDate(schedule.today.date),
      hijriDate: state.hijriDate.format(format),
      locating: state.locating,
      onCityTap: cubit.refresh,
      qiblaLabel: tablet ? _qiblaLabel(context) : null,
      onQiblaTap: () => context.go(AppRoutes.qibla),
      tablet: tablet,
    );

    return ResponsiveBuilder(
      phone: (context) => _PhoneFrame(
        header: header(tablet: false),
        hero: NextPrayerCard(schedule: schedule),
        list: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TodayTitle(),
            PrayerList(schedule: schedule),
          ],
        ),
      ),
      tablet: (context) => _TabletFrame(
        header: header(tablet: true),
        hero: NextPrayerCard(schedule: schedule, tablet: true),
        list: PrayerList(schedule: schedule, tablet: true),
      ),
    );
  }

  String _qiblaLabel(BuildContext context) {
    final bearing = qiblaBearing(state.location.coordinates);
    return LocaleKeys.home_qibla_bearing.tr(
      args: [
        context.format.number(bearing.round() % 360),
        compassPoint(bearing).label,
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: LocaleKeys.home_loading_title.tr(),
      child: ResponsiveBuilder(
        phone: (context) => _PhoneFrame(
          header: const SkeletonHeader(),
          hero: const SkeletonHeroCard(),
          list: const SkeletonPrayerList(),
          footer: Padding(
            padding: EdgeInsetsDirectional.only(top: HayyaSpacing.s4),
            child: Text(
              LocaleKeys.home_loading_body.tr(),
              textAlign: TextAlign.center,
              style: context.type
                  .style(13, FontWeight.w600)
                  .copyWith(color: c.muted),
            ),
          ),
        ),
        tablet: (context) => const _TabletFrame(
          header: SkeletonHeader(tablet: true),
          hero: SkeletonHeroCard(tablet: true),
          list: SkeletonPrayerList(tablet: true),
        ),
      ),
    );
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError(this.state);

  final PrayerTimesLocationError state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerTimesCubit>();
    return LocationErrorView(
      reason: state.reason,
      lastKnown: state.lastKnown,
      onRetry: cubit.refresh,
      onUseLastKnown: cubit.useLastKnown,
      onOpenSettings: () => cubit.openSettingsFor(state.reason),
    );
  }
}

/// "Today" with the timetable link at the end. The link's 44 px tap
/// height takes the place of the design's 36 px link and 4 px of the
/// padding above and below it.
class _TodayTitle extends StatelessWidget {
  const _TodayTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        HayyaSpacing.s1,
        14.r,
        0,
        HayyaSpacing.s1,
      ),
      // With large text the link moves under the title.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(
              LocaleKeys.home_today.tr(),
              style: context.type
                  .style(18, FontWeight.w800)
                  .copyWith(color: context.colors.text),
            ),
          ),
          const TimetableLink(),
        ],
      ),
    );
  }
}

/// Phone Home: the header under the status bar, the hero card overlapping
/// its bottom 92 px, then the "Today" list. The header grows past its
/// 200 px with large text.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({
    required this.header,
    required this.hero,
    required this.list,
    this.footer,
  });

  final Widget header;
  final Widget hero;
  final Widget list;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: OverlapLayout(
        minHeaderHeight: MediaQuery.paddingOf(context).top + 200.r,
        overlap: 92.r,
        header: header,
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            HayyaSpacing.s4,
            0,
            HayyaSpacing.s4,
            HayyaSpacing.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [hero, list, ?footer],
          ),
        ),
      ),
    );
  }
}

/// Tablet Home: a shorter header with the hero and list side by side
/// over it (the header grows with large text). When the space is too narrow for both columns (portrait), the
/// list moves under the hero.
class _TabletFrame extends StatelessWidget {
  const _TabletFrame({
    required this.header,
    required this.hero,
    required this.list,
  });

  final Widget header;
  final Widget hero;
  final Widget list;

  /// Hero (420) + gap (24) + the narrowest list that fits a large row.
  static const _twoColumnWidth = 940.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final headerHeight = top + 236.r;
    final contentTop = top + 164.r;
    final gutter = 32.r;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 2 * gutter;
        final twoColumns = width >= _twoColumnWidth.r;
        final minHeight = math.max(
          0.0,
          constraints.maxHeight - contentTop - gutter,
        );

        final content = twoColumns
            ? ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: HayyaSpacing.s6,
                    children: [
                      SizedBox(width: 420.r, child: hero),
                      Expanded(child: list),
                    ],
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: HayyaSpacing.s6,
                children: [hero, list],
              );

        return SingleChildScrollView(
          child: OverlapLayout(
            minHeaderHeight: headerHeight,
            overlap: headerHeight - contentTop,
            header: header,
            body: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                0,
                gutter,
                gutter,
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
