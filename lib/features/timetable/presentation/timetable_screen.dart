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
import '../../settings/presentation/calculation_display.dart';
import 'cubit/timetable_cubit.dart';
import 'cubit/timetable_state.dart';
import 'timetable_display.dart';
import 'widgets/month_switcher.dart';
import 'widgets/timetable_table.dart';

/// The month's prayer times, opened from Home.
///
/// Phones follow the design. Tablets center the same layout at a readable
/// width, with larger rows and room for AM/PM.
class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TimetableCubit>()..start(),
      child: const _TimetableView(),
    );
  }
}

class _TimetableView extends StatefulWidget {
  const _TimetableView();

  @override
  State<_TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<_TimetableView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back after midnight, the highlight moves to the new day.
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<TimetableCubit>().refreshToday(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// A tablet keeps the table about as wide as it reads well.
  static const _tabletMaxWidth = 760.0;

  @override
  Widget build(BuildContext context) {
    // Rebuild text when the language changes.
    context.locale;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tablet = constraints.isTablet;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: tablet ? _tabletMaxWidth.r : double.infinity,
                ),
                child: Padding(
                  padding: tablet
                      ? EdgeInsetsDirectional.fromSTEB(
                          HayyaSpacing.s6,
                          HayyaSpacing.s4,
                          HayyaSpacing.s6,
                          HayyaSpacing.s6,
                        )
                      : EdgeInsetsDirectional.fromSTEB(
                          HayyaSpacing.s3,
                          HayyaSpacing.s1,
                          HayyaSpacing.s3,
                          HayyaSpacing.s3,
                        ),
                  child: BlocBuilder<TimetableCubit, TimetableState>(
                    builder: (context, state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TitleRow(tablet: tablet),
                        Expanded(
                          child: switch (state) {
                            TimetableReady() => _Ready(state, tablet: tablet),
                            TimetableNoLocation() => const _NoLocation(),
                          },
                        ),
                      ],
                    ),
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

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.tablet});

  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: HayyaSpacing.s2,
      children: [
        SquareIconButton(
          icon: HayyaIcons.back,
          label: LocaleKeys.timetable_back.tr(),
          onTap: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              LocaleKeys.timetable_title.tr(),
              style: context.type
                  .style(tablet ? 24 : 20, FontWeight.w800)
                  .copyWith(color: context.colors.text),
            ),
          ),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready(this.state, {required this.tablet});

  final TimetableReady state;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimetableCubit>();
    final format = context.format;
    final c = context.colors;
    final hours = format.use24Hour ? 24 : 12;
    final inset = tablet ? 0.0 : HayyaSpacing.s1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: HayyaSpacing.s2),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: inset),
          child: MonthSwitcher(
            month: format.monthYear(state.month.firstDay),
            hijriRange: state.timetable.hijriRange(format),
            previousLabel: LocaleKeys.timetable_previous_month.tr(),
            nextLabel: LocaleKeys.timetable_next_month.tr(),
            onPrevious: cubit.showPreviousMonth,
            onNext: cubit.showNextMonth,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            inset + HayyaSpacing.s1,
            10.r,
            inset + HayyaSpacing.s1,
            10.r,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6.r,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(top: 2.r),
                child: HayyaIcon(
                  HayyaIcons.location,
                  size: 14,
                  strokeWidth: 2,
                  color: c.muted,
                ),
              ),
              Expanded(
                child: Text(
                  LocaleKeys.timetable_meta.tr(
                    args: [
                      state.location.cityName(context.locale),
                      state.settings.method.localizedName,
                      LocaleKeys.settings_time_hours.tr(
                        args: [format.number(hours)],
                      ),
                    ],
                  ),
                  style: context.type
                      .style(12.5, FontWeight.w600)
                      .copyWith(color: c.muted),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TimetableTable(
            key: ValueKey(state.month),
            timetable: state.timetable,
            today: state.today,
            tablet: tablet,
          ),
        ),
      ],
    );
  }
}

class _NoLocation extends StatelessWidget {
  const _NoLocation();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(HayyaSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: HayyaSpacing.s2,
          children: [
            HayyaIcon(HayyaIcons.pinOff, size: 40, color: c.muted),
            Text(
              LocaleKeys.timetable_no_location_title.tr(),
              textAlign: TextAlign.center,
              style: context.type.title.copyWith(color: c.text),
            ),
            Text(
              LocaleKeys.timetable_no_location_body.tr(),
              textAlign: TextAlign.center,
              style: context.type.body.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
