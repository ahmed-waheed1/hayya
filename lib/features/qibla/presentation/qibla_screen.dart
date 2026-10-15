import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/hayya_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/localized_format.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/widgets.dart';
import '../../../generated/locale_keys.g.dart';
import '../../prayer_times/presentation/prayer_display.dart';
import '../../prayer_times/presentation/widgets/location_status_view.dart';
import '../domain/heading_math.dart';
import 'cubit/qibla_cubit.dart';
import 'cubit/qibla_state.dart';
import 'widgets/compass_help_cards.dart';
import 'widgets/qibla_dial.dart';
import 'widgets/qibla_status_pill.dart';
import 'widgets/qibla_stats.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QiblaCubit>()..start(),
      child: const _QiblaView(),
    );
  }
}

class _QiblaView extends StatefulWidget {
  const _QiblaView();

  @override
  State<_QiblaView> createState() => _QiblaViewState();
}

/// Runs the compass only while this tab is on screen and the app is in the
/// foreground. The tab stays alive behind the others (its [TickerMode] is
/// off then), and the sensor costs battery.
class _QiblaViewState extends State<_QiblaView> {
  late final AppLifecycleListener _lifecycle;
  ValueListenable<TickerModeData>? _onScreen;
  bool _appVisible = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _appVisible = state == AppLifecycleState.resumed;
        _syncCompass();
      },
      // Back from the system settings, the permission or GPS may be on now.
      onResume: () => context.read<QiblaCubit>().recheck(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final onScreen = TickerMode.getValuesNotifier(context);
    if (onScreen != _onScreen) {
      _onScreen?.removeListener(_syncCompass);
      _onScreen = onScreen..addListener(_syncCompass);
      _syncCompass();
    }
  }

  void _syncCompass() => context.read<QiblaCubit>().setCompassActive(
    _appVisible && (_onScreen?.value.enabled ?? true),
  );

  @override
  void dispose() {
    _onScreen?.removeListener(_syncCompass);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild text when the language changes.
    context.locale;
    return Scaffold(
      body: BlocConsumer<QiblaCubit, QiblaState>(
        // One pulse each time the phone comes into line.
        listenWhen: (previous, current) =>
            current is QiblaReady &&
            current.aligned &&
            !(previous is QiblaReady && previous.aligned),
        listener: (context, state) => HapticFeedback.mediumImpact(),
        builder: (context, state) => switch (state) {
          QiblaLoading() => const _Loading(),
          QiblaReady() => _Ready(state),
          QiblaLocationError() => _LocationError(state),
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: HayyaSpacing.s4,
        children: [
          CircularProgressIndicator(color: c.primary),
          Text(
            LocaleKeys.qibla_loading.tr(),
            textAlign: TextAlign.center,
            style: context.type
                .style(14, FontWeight.w600)
                .copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError(this.state);

  final QiblaLocationError state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QiblaCubit>();
    return LocationErrorView(
      reason: state.reason,
      lastKnown: state.lastKnown,
      onRetry: cubit.refresh,
      onUseLastKnown: cubit.useLastKnown,
      onOpenSettings: () => cubit.openSettingsFor(state.reason),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready(this.state);

  final QiblaReady state;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      phone: (context) => _SingleColumn(state, maxDial: 300.r),
      tablet: (context) => LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= _TwoColumns.minWidth.r
            ? _TwoColumns(state)
            : _SingleColumn(state, maxDial: 380.r, tablet: true),
      ),
    );
  }
}

/// Phone, and portrait tablets: the Qibla frame top to bottom.
class _SingleColumn extends StatelessWidget {
  const _SingleColumn(this.state, {required this.maxDial, this.tablet = false});

  final QiblaReady state;
  final double maxDial;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final gutter = HayyaSpacing.screenGutter;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(
            constraints.maxWidth,
            tablet ? 600.r : double.infinity,
          );
          final dial = math.min(maxDial, width - 2 * gutter);
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(bottom: HayyaSpacing.s6),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        gutter,
                        tablet ? HayyaSpacing.s8 : HayyaSpacing.s2,
                        gutter,
                        0,
                      ),
                      child: _Header(state, tablet: tablet),
                    ),
                    SizedBox(height: 22.r),
                    Center(child: QiblaStatusPill(state: state)),
                    SizedBox(height: 30.r),
                    _DialWithCalibration(state, size: dial),
                    ..._details(state, horizontal: gutter),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Landscape tablets: the dial on the start side, the readouts beside it.
class _TwoColumns extends StatelessWidget {
  const _TwoColumns(this.state);

  final QiblaReady state;

  /// Dial column + gap + side column, in design px.
  static const minWidth = 880.0;

  @override
  Widget build(BuildContext context) {
    final gutter = 40.r;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideWidth = 400.r;
          final dial = math.min(
            420.r,
            constraints.maxWidth - 2 * gutter - sideWidth - HayyaSpacing.s12,
          );
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              HayyaSpacing.s8,
              gutter,
              HayyaSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: HayyaSpacing.s8,
              children: [
                _Header(state, tablet: true),
                Row(
                  spacing: HayyaSpacing.s12,
                  children: [
                    Expanded(
                      child: Column(
                        spacing: 28.r,
                        children: [
                          QiblaStatusPill(state: state),
                          _Dial(state, size: dial),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: sideWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.compass == CompassStatus.calibrating)
                            Padding(
                              padding: EdgeInsetsDirectional.only(
                                bottom: HayyaSpacing.s4,
                              ),
                              child: CalibrationCard(accuracy: state.accuracy),
                            ),
                          ..._details(state, horizontal: 0, first: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// What goes under (or beside) the dial: the no-sensor help and Retry, or
/// the stats; then the hint.
List<Widget> _details(
  QiblaReady state, {
  required double horizontal,
  bool first = false,
}) {
  EdgeInsetsDirectional gap(double top) => EdgeInsetsDirectional.fromSTEB(
    horizontal,
    first ? 0 : top,
    horizontal,
    0,
  );
  final hint = switch (state.compass) {
    CompassStatus.live when state.aligned => LocaleKeys.qibla_hint_aligned,
    CompassStatus.live => LocaleKeys.qibla_hint_seek,
    _ => null,
  };

  return [
    if (state.compass == CompassStatus.noSensor) ...[
      Padding(
        padding: gap(26.r),
        child: NoSensorCard(bearing: state.bearing),
      ),
      Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          horizontal,
          18.r,
          horizontal,
          0,
        ),
        child: Builder(
          builder: (context) => HayyaButton(
            label: LocaleKeys.qibla_retry.tr(),
            icon: HayyaIcons.retry,
            variant: HayyaButtonVariant.soft,
            expand: true,
            onPressed: context.read<QiblaCubit>().retryCompass,
          ),
        ),
      ),
    ] else
      Padding(
        padding: gap(30.r),
        child: QiblaStats(bearing: state.bearing, distanceKm: state.distanceKm),
      ),
    if (hint != null)
      Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          horizontal + 8.r,
          HayyaSpacing.s4,
          horizontal + 8.r,
          0,
        ),
        child: Builder(
          builder: (context) => Text(
            hint.tr(),
            textAlign: TextAlign.center,
            style: context.type
                .style(
                  13.5,
                  FontWeight.w500,
                  height: context.type.isArabic ? 1.8 : 1.6,
                )
                .copyWith(color: context.colors.muted),
          ),
        ),
      ),
  ];
}

class _Header extends StatelessWidget {
  const _Header(this.state, {required this.tablet});

  final QiblaReady state;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    // Both loose, so each keeps its own width and they sit at either end;
    // a long city name shrinks (ellipsized) before the title does.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: HayyaSpacing.s3,
      children: [
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              LocaleKeys.qibla_title.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (tablet ? type.titleLarge : type.style(26, FontWeight.w800))
                      .copyWith(color: c.text),
            ),
          ),
        ),
        Flexible(
          child: Container(
            constraints: BoxConstraints(minHeight: 36.r),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: HayyaSpacing.s3,
            ),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(HayyaSpacing.s3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6.r,
              children: [
                HayyaIcon(
                  HayyaIcons.location,
                  size: 16,
                  color: c.muted,
                  strokeWidth: 2,
                ),
                Flexible(
                  child: Text(
                    state.location.cityName(context.locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type
                        .style(14, FontWeight.w700)
                        .copyWith(color: c.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The dial, with the calibration card over it. The card is in the flow
/// (not floating) so a long translation pushes the stats down instead of
/// covering them.
class _DialWithCalibration extends StatelessWidget {
  const _DialWithCalibration(this.state, {required this.size});

  final QiblaReady state;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.topCenter,
      children: [
        _Dial(state, size: size),
        if (state.compass == CompassStatus.calibrating)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              HayyaSpacing.s6,
              52.r,
              HayyaSpacing.s6,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: CalibrationCard(accuracy: state.accuracy),
            ),
          ),
      ],
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial(this.state, {required this.size});

  final QiblaReady state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final format = context.format;
    final heading = state.heading;
    final label = heading == null
        ? LocaleKeys.qibla_dial_label.tr(
            args: [format.number(state.bearing.round() % 360)],
          )
        : LocaleKeys.qibla_dial_label_heading.tr(
            args: [
              format.number(state.bearing.round() % 360),
              format.number(normalizeDegrees(heading).round() % 360),
            ],
          );
    return Center(
      child: QiblaDial(
        bearing: state.bearing,
        heading: heading,
        aligned: state.aligned,
        dimmed: state.compass == CompassStatus.calibrating,
        size: size,
        semanticLabel: label,
      ),
    );
  }
}
