import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/preferences/language_switcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/user_location.dart';
import '../../../core/theme/hayya_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/localized_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../generated/locale_keys.g.dart';
import '../../prayer_times/presentation/prayer_display.dart';
import '../../prayer_times/presentation/widgets/home_header.dart';
import '../../qibla/domain/qibla_direction.dart';
import '../../qibla/presentation/qibla_display.dart';
import '../../settings/presentation/cubit/location_settings_cubit.dart';
import '../../settings/presentation/widgets/city_search.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';
import 'widgets/onboarding_hero.dart';

/// First launch: welcome, location, notifications. See [OnboardingCubit].
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the system settings, location may be on now.
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<OnboardingCubit>().recheckLocation(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// A tablet keeps the slide about phone width.
  static const _maxWidth = 460.0;

  @override
  Widget build(BuildContext context) {
    // Rebuild text when the language changes.
    context.locale;
    final c = context.colors;
    return BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (before, now) => !before.done && now.done,
      listener: (context, state) => context.go(AppRoutes.home),
      child: Scaffold(
        body: Stack(
          children: [
            // The pattern fades in from the top, as on the error states.
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              height: 460.r,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.transparent],
                ).createShader(rect),
                child: CustomPaint(
                  painter: HeaderPatternPainter(
                    color: c.primaryInk.withValues(
                      alpha: context.isDark ? 0.12 : 0.10,
                    ),
                    tile: 56.r,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: _maxWidth.r),
                        child: BlocBuilder<OnboardingCubit, OnboardingState>(
                          builder: (context, state) => _Slide(
                            state: state,
                            width: constraints.maxWidth
                                .clamp(0.0, _maxWidth.r)
                                .toDouble(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One slide's content for [state]: what it says and what its buttons do.
class _SlideContent {
  const _SlideContent({
    required this.over,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.icon,
    this.badge,
    this.badgeIcon,
    this.secondary,
    this.onSecondary,
    this.extra,
    this.onExtra,
  });

  final String over;
  final String title;
  final String body;
  final HayyaIconData? icon;
  final String? badge;
  final HayyaIconData? badgeIcon;

  /// The main button; [onAction] null while waiting.
  final String action;
  final VoidCallback? onAction;

  /// The text button under it.
  final String? secondary;
  final VoidCallback? onSecondary;

  /// A link under the body: open settings, try again.
  final String? extra;
  final VoidCallback? onExtra;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.state, required this.width});

  final OnboardingState state;
  final double width;

  _SlideContent _content(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final format = context.format;
    String step(int n) => LocaleKeys.onboarding_step.tr(
      args: [format.number(n), format.number(2)],
    );

    switch (state.page) {
      case OnboardingPage.welcome:
        return _SlideContent(
          over: LocaleKeys.onboarding_welcome_over.tr(),
          title: LocaleKeys.onboarding_welcome_title.tr(),
          body: LocaleKeys.onboarding_welcome_body.tr(),
          action: LocaleKeys.onboarding_get_started.tr(),
          onAction: cubit.next,
        );

      case OnboardingPage.location:
        final location = state.location;
        final failure = state.locationFailure;
        final badge = location == null
            ? null
            : LocaleKeys.onboarding_badge.tr(
                args: [
                  location.cityName(context.locale),
                  _qiblaLabel(context, location.coordinates),
                ],
              );
        final common = (
          over: step(1),
          title: LocaleKeys.onboarding_location_title.tr(),
          icon: HayyaIcons.location,
          badge: badge,
        );
        if (location != null) {
          // Back from the next slide: already found.
          return _SlideContent(
            over: common.over,
            title: common.title,
            icon: common.icon,
            badge: common.badge,
            badgeIcon: HayyaIcons.location,
            body: LocaleKeys.onboarding_location_body.tr(),
            action: LocaleKeys.onboarding_continue.tr(),
            onAction: cubit.next,
          );
        }
        if (failure != null) {
          return _SlideContent(
            over: common.over,
            title: common.title,
            icon: HayyaIcons.pinOff,
            body: switch (failure) {
              LocationFailure.permissionDenied =>
                LocaleKeys.onboarding_location_denied_body.tr(),
              LocationFailure.permissionDeniedForever =>
                LocaleKeys.onboarding_location_blocked_body.tr(),
              LocationFailure.serviceDisabled =>
                LocaleKeys.onboarding_location_off_body.tr(),
              LocationFailure.unavailable =>
                LocaleKeys.onboarding_location_unavailable_body.tr(),
            },
            action: LocaleKeys.onboarding_choose_city.tr(),
            onAction: () => _chooseCity(context),
            secondary: LocaleKeys.onboarding_continue_without_location.tr(),
            onSecondary: cubit.next,
            extra: switch (failure) {
              LocationFailure.permissionDenied => null,
              LocationFailure.permissionDeniedForever =>
                LocaleKeys.location_open_settings.tr(),
              LocationFailure.serviceDisabled =>
                LocaleKeys.location_location_settings.tr(),
              LocationFailure.unavailable => LocaleKeys.location_try_again.tr(),
            },
            onExtra: failure == LocationFailure.unavailable
                ? cubit.allowLocation
                : () => cubit.openSettingsFor(failure),
          );
        }
        return _SlideContent(
          over: common.over,
          title: common.title,
          icon: common.icon,
          body: state.locating
              ? LocaleKeys.onboarding_locating.tr()
              : LocaleKeys.onboarding_location_body.tr(),
          action: LocaleKeys.onboarding_allow_location.tr(),
          onAction: state.locating ? null : cubit.allowLocation,
          secondary: LocaleKeys.onboarding_choose_city.tr(),
          onSecondary: state.locating ? null : () => _chooseCity(context),
        );

      case OnboardingPage.notifications:
        final next = state.nextPrayer;
        final clock = next == null ? null : format.clock(next.time);
        final badge = next == null
            ? null
            : LocaleKeys.onboarding_badge.tr(
                args: [
                  next.prayer.localizedName,
                  '${clock!.time} ${clock.meridiem}'.trim(),
                ],
              );
        if (state.notificationsDenied) {
          return _SlideContent(
            over: step(2),
            title: LocaleKeys.onboarding_notifications_title.tr(),
            icon: HayyaIcons.bellOff,
            body: LocaleKeys.onboarding_notifications_denied_body.tr(),
            action: LocaleKeys.onboarding_continue.tr(),
            onAction: cubit.finish,
          );
        }
        return _SlideContent(
          over: step(2),
          title: LocaleKeys.onboarding_notifications_title.tr(),
          icon: HayyaIcons.bell,
          badge: badge,
          badgeIcon: HayyaIcons.reminder,
          body: LocaleKeys.onboarding_notifications_body.tr(),
          action: LocaleKeys.onboarding_allow_notifications.tr(),
          onAction: state.requestingNotifications
              ? null
              : cubit.allowNotifications,
          secondary: LocaleKeys.onboarding_maybe_later.tr(),
          onSecondary: state.requestingNotifications ? null : cubit.finish,
        );
    }
  }

  static String _qiblaLabel(BuildContext context, GeoCoordinates coordinates) {
    final bearing = qiblaBearing(coordinates);
    return LocaleKeys.home_qibla_bearing.tr(
      args: [
        context.format.number(bearing.round() % 360),
        compassPoint(bearing).label,
      ],
    );
  }

  Future<void> _chooseCity(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => getIt<LocationSettingsCubit>()..showManual(),
      child: const _CitySheet(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final content = _content(context);
    final cubit = context.read<OnboardingCubit>();
    final welcome = state.page == OnboardingPage.welcome;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        HayyaSpacing.s5,
        HayyaSpacing.s3,
        HayyaSpacing.s5,
        HayyaSpacing.s6,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s6,
        children: [
          // Language (first slide) or back, then Skip; with large text
          // Skip moves to its own line.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: HayyaSpacing.s2,
            children: [
              if (welcome)
                const _LanguageToggle()
              else
                SquareIconButton(
                  icon: HayyaIcons.back,
                  label: LocaleKeys.onboarding_back.tr(),
                  onTap: cubit.back,
                  filled: true,
                ),
              HayyaButton(
                label: LocaleKeys.onboarding_skip.tr(),
                onPressed: cubit.finish,
                variant: HayyaButtonVariant.text,
              ),
            ],
          ),
          Column(
            spacing: HayyaSpacing.s3,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: 44.r),
                child: OnboardingHero(
                  icon: content.icon,
                  badge: content.badge,
                  badgeIcon: content.badgeIcon,
                  maxWidth: width,
                ),
              ),
              Text(
                content.over,
                textAlign: TextAlign.center,
                style: type
                    .style(13, FontWeight.w800, trackingEm: 0.12)
                    .copyWith(color: c.goldInk),
              ),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  content.title,
                  textAlign: TextAlign.center,
                  style: type
                      .style(
                        30,
                        FontWeight.w800,
                        trackingEm: -0.01,
                        height: type.isArabic ? 1.45 : 1.15,
                      )
                      .copyWith(color: c.text),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 310.r),
                child: Text(
                  content.body,
                  textAlign: TextAlign.center,
                  style: type
                      .style(
                        16,
                        FontWeight.w500,
                        height: type.isArabic ? 1.75 : 1.55,
                      )
                      .copyWith(color: c.muted),
                ),
              ),
              if (content.extra case final extra?)
                HayyaButton(
                  label: extra,
                  onPressed: content.onExtra,
                  variant: HayyaButtonVariant.text,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18.r,
            children: [
              _Dots(index: state.page.index),
              HayyaButton(
                label: content.action,
                onPressed: content.onAction,
                expand: true,
              ),
              if (content.secondary case final secondary?)
                Center(
                  child: HayyaButton(
                    label: secondary,
                    onPressed: content.onSecondary,
                    variant: HayyaButtonVariant.text,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// English / العربية, each name in its own script's font (the design's
/// compact toggle, at its natural width).
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = context.locale.languageCode;
    Widget option(String code, String label, TextStyle style) {
      final selected = code == current;
      final radius = BorderRadius.circular(11.r);
      return Flexible(
        child: Semantics(
          button: true,
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: Material(
            color: selected ? c.selectedSurface : Colors.transparent,
            borderRadius: radius,
            elevation: selected ? 1 : 0,
            child: InkWell(
              onTap: selected ? null : () => context.switchLanguage(code),
              borderRadius: radius,
              child: Container(
                constraints: BoxConstraints(minHeight: 38.r),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 14.r,
                  vertical: 4.r,
                ),
                // Centered at its natural width (an alignment would
                // stretch it to all the space the Flexible offers).
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: style.copyWith(color: selected ? c.text : c.muted),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: LocaleKeys.onboarding_language_label.tr(),
      container: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(4.r),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4.r,
          children: [
            option(
              'en',
              LocaleKeys.settings_language_english.tr(),
              context.type.style(14, FontWeight.w700),
            ),
            option(
              'ar',
              LocaleKeys.settings_language_arabic.tr(),
              context.type.arabic(15, FontWeight.w700, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Which slide this is: the current one long, the others short.
class _Dots extends StatelessWidget {
  const _Dots({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: HayyaSpacing.s2,
        children: [
          for (var i = 0; i < OnboardingPage.values.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: (i == index ? 28 : 8).r,
              height: 8.r,
              decoration: BoxDecoration(
                color: i == index ? c.primary : c.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Choose a city manually": the same search as Settings. Choosing one
/// closes the sheet; onboarding moves on when the location changes.
class _CitySheet extends StatelessWidget {
  const _CitySheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(20.r, 10.r, 20.r, 24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: HayyaSpacing.s4,
          children: [
            Center(
              child: Container(
                width: 40.r,
                height: 4.r,
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                LocaleKeys.onboarding_choose_city_title.tr(),
                style: context.type
                    .style(20, FontWeight.w800)
                    .copyWith(color: c.text),
              ),
            ),
            CitySearch(
              autofocus: true,
              onChosen: (_) => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
