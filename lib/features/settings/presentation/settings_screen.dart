import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/hayya_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/widgets.dart';
import '../../../generated/locale_keys.g.dart';
import '../../notifications/domain/adhan_scheduler.dart';
import '../../notifications/presentation/widgets/notification_settings_group.dart';
import 'cubit/location_settings_cubit.dart';
import 'cubit/prayer_settings_cubit.dart';
import 'widgets/about_group.dart';
import 'widgets/general_group.dart';
import 'widgets/location_group.dart';
import 'widgets/prayer_times_group.dart';

/// Settings, in the design's order: General, Prayer times, Manual
/// adjustments, Notifications, Location; then About (not in the design)
/// and, in debug builds, Developer.
///
/// Phones (and narrow tablet panes) get one column; wider tablets get two.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Below this width two columns would be narrower than a phone's.
  static const _twoColumnsFrom = 760.0;

  /// A single column on a tablet stays about phone-width plus a margin.
  static const _singleColumnMaxWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    // Rebuild text when the language changes.
    context.locale;
    final sections = <Widget>[
      _section(LocaleKeys.settings_general, const GeneralGroup()),
      _section(LocaleKeys.settings_prayer_times, const PrayerTimesGroup()),
      _section(LocaleKeys.settings_adjustments, const AdjustmentsGroup()),
      _section(
        LocaleKeys.settings_notifications,
        const NotificationSettingsGroup(),
      ),
      _section(LocaleKeys.settings_location, const LocationGroup()),
      _section(LocaleKeys.settings_about, const AboutGroup()),
      if (kDebugMode)
        _section(LocaleKeys.settings_developer, const _DeveloperGroup()),
    ];

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<PrayerSettingsCubit>()),
        BlocProvider(create: (_) => getIt<LocationSettingsCubit>()),
      ],
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = EdgeInsetsDirectional.fromSTEB(
                HayyaSpacing.s4,
                HayyaSpacing.s4,
                HayyaSpacing.s4,
                HayyaSpacing.s8,
              );
              final width = constraints.maxWidth - padding.horizontal;
              if (constraints.isTablet && width >= _twoColumnsFrom) {
                return _TwoColumns(padding: padding, sections: sections);
              }
              return ListView(
                padding: padding,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.isTablet
                            ? _singleColumnMaxWidth
                            : double.infinity,
                      ),
                      child: _Column(children: [const _Title(), ...sections]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _section(String titleKey, Widget child) =>
      SettingsSection(title: titleKey.tr(), child: child);
}

/// The design's 22 px between sections.
class _Column extends StatelessWidget {
  const _Column({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 22.r,
    children: children,
  );
}

/// The first three sections (General, Prayer times, Adjustments) on the
/// start side, the rest on the end side, scrolling together.
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.padding, required this.sections});

  final EdgeInsetsDirectional padding;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 22.r,
        children: [
          const _Title(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: HayyaSpacing.s6,
            children: [
              Expanded(child: _Column(children: sections.sublist(0, 3))),
              Expanded(child: _Column(children: sections.sublist(3))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HayyaSpacing.minTouchTarget),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: HayyaSpacing.s1),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            header: true,
            child: Text(
              LocaleKeys.settings_title.tr(),
              style: context.type
                  .style(26, FontWeight.w800)
                  .copyWith(color: context.colors.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeveloperGroup extends StatelessWidget {
  const _DeveloperGroup();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: HayyaSpacing.s2,
      children: [
        SettingsTile(
          title: LocaleKeys.settings_test_adhan.tr(),
          onTap: () => _testAdhan(context),
        ),
      ],
    );
  }
}

/// Debug only: a real adhan notification one minute from now.
Future<void> _testAdhan(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = LocaleKeys.settings_test_adhan_scheduled.tr();
  await getIt<AdhanScheduler>().scheduleTest();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
