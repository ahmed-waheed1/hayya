import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/hayya_theme.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import 'preview_section.dart';

/// Light and dark panels side by side on tablet, stacked on phone —
/// mirroring the "Components" block of the design system frame.
class ComponentsPanels extends StatelessWidget {
  const ComponentsPanels({super.key});

  @override
  Widget build(BuildContext context) {
    final light = _ComponentsPanel(
      theme: HayyaTheme.light(context.locale),
      title: LocaleKeys.design_preview_light.tr(),
    );
    final dark = _ComponentsPanel(
      theme: HayyaTheme.dark(context.locale),
      title: LocaleKeys.design_preview_dark.tr(),
    );
    return ResponsiveBuilder(
      phone: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s6,
        children: [light, dark],
      ),
      tablet: (_) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HayyaSpacing.s6,
        children: [
          Expanded(child: light),
          Expanded(child: dark),
        ],
      ),
    );
  }
}

class _ComponentsPanel extends StatelessWidget {
  const _ComponentsPanel({required this.theme, required this.title});

  final ThemeData theme;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final c = context.colors;
          return DefaultTextStyle.merge(
            style: TextStyle(color: c.text),
            child: Container(
              padding: EdgeInsetsDirectional.all(HayyaSpacing.s5),
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: HayyaSpacing.s6,
                children: [
                  Text(title, style: context.type.title),
                  _Group(
                    label: LocaleKeys.design_preview_buttons.tr(),
                    child: const _ButtonsDemo(),
                  ),
                  _Group(
                    label: LocaleKeys.design_preview_toggles.tr(),
                    child: const _TogglesDemo(),
                  ),
                  _Group(
                    label: LocaleKeys.design_preview_prayer_rows.tr(),
                    child: const _PrayerRowsDemo(),
                  ),
                  _Group(
                    label: LocaleKeys.design_preview_tiles.tr(),
                    child: const _TilesDemo(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HayyaSpacing.s3,
      children: [
        Text(
          label,
          style: context.type.overline.copyWith(color: context.colors.muted),
        ),
        child,
      ],
    );
  }
}

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Wrap(
      spacing: HayyaSpacing.s3,
      runSpacing: HayyaSpacing.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        HayyaButton(
          label: LocaleKeys.onboarding_allow_location.tr(),
          onPressed: noop,
        ),
        HayyaButton(
          label: LocaleKeys.onboarding_not_now.tr(),
          variant: HayyaButtonVariant.soft,
          onPressed: noop,
        ),
        HayyaButton(
          label: LocaleKeys.onboarding_skip.tr(),
          variant: HayyaButtonVariant.text,
          onPressed: noop,
        ),
        HayyaButton(
          label: LocaleKeys.tracker_log_prayer.tr(),
          variant: HayyaButtonVariant.gold,
          icon: HayyaIcons.add,
          onPressed: noop,
        ),
        HayyaButton(label: LocaleKeys.common_disabled.tr(), onPressed: null),
        HayyaIconButton(
          icon: HayyaIcons.bell,
          semanticLabel: LocaleKeys.settings_adhan_notification.tr(),
          onPressed: noop,
        ),
      ],
    );
  }
}

class _TogglesDemo extends StatefulWidget {
  const _TogglesDemo();

  @override
  State<_TogglesDemo> createState() => _TogglesDemoState();
}

class _TogglesDemoState extends State<_TogglesDemo> {
  // Local demo state only; real screens drive these from a Cubit.
  bool _switchA = true;
  bool _switchB = false;
  bool _checkA = true;
  bool _checkB = false;
  bool _bellA = true;
  bool _bellB = false;
  ThemeMode _segment = ThemeMode.dark;
  int _radio = 0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: HayyaSpacing.s4,
      runSpacing: HayyaSpacing.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        HayyaSwitch(
          value: _switchA,
          semanticLabel: LocaleKeys.common_on.tr(),
          onChanged: (v) => setState(() => _switchA = v),
        ),
        HayyaSwitch(
          value: _switchB,
          semanticLabel: LocaleKeys.common_off.tr(),
          onChanged: (v) => setState(() => _switchB = v),
        ),
        PrayedCheck(
          value: _checkA,
          semanticLabel: LocaleKeys.prayers_mark_as_prayed.tr(),
          onChanged: (v) => setState(() => _checkA = v),
        ),
        PrayedCheck(
          value: _checkB,
          semanticLabel: LocaleKeys.prayers_mark_as_prayed.tr(),
          onChanged: (v) => setState(() => _checkB = v),
        ),
        AdhanToggle(
          value: _bellA,
          semanticLabel: LocaleKeys.settings_adhan_notification.tr(),
          onChanged: (v) => setState(() => _bellA = v),
        ),
        AdhanToggle(
          value: _bellB,
          semanticLabel: LocaleKeys.settings_adhan_notification.tr(),
          onChanged: (v) => setState(() => _bellB = v),
        ),
        SegmentedPicker<ThemeMode>(
          options: [
            SegmentOption(
              value: ThemeMode.light,
              label: LocaleKeys.settings_theme_light.tr(),
            ),
            SegmentOption(
              value: ThemeMode.dark,
              label: LocaleKeys.settings_theme_dark.tr(),
            ),
            SegmentOption(
              value: ThemeMode.system,
              label: LocaleKeys.settings_theme_system.tr(),
            ),
          ],
          value: _segment,
          onChanged: (v) => setState(() => _segment = v),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 2; i++)
              HayyaRadio(
                selected: _radio == i,
                onTap: () => setState(() => _radio = i),
              ),
          ],
        ),
      ],
    );
  }
}

class _PrayerRowsDemo extends StatefulWidget {
  const _PrayerRowsDemo();

  @override
  State<_PrayerRowsDemo> createState() => _PrayerRowsDemoState();
}

class _PrayerRowsDemoState extends State<_PrayerRowsDemo> {
  bool _fajrBell = true;
  bool _fajrPrayed = true;
  bool _sunriseBell = false;
  bool _dhuhrBell = true;
  bool _dhuhrPrayed = false;

  @override
  Widget build(BuildContext context) {
    final fajr = formatSampleTime(context, 5, 28);
    final sunrise = formatSampleTime(context, 6, 53);
    final dhuhr = formatSampleTime(context, 12, 39);
    return PrayerRowGroup(
      children: [
        PrayerRow(
          icon: HayyaIcons.fajr,
          name: LocaleKeys.prayers_fajr.tr(),
          time: fajr.time,
          meridiem: fajr.meridiem,
          adhanOn: _fajrBell,
          onToggleAdhan: (v) => setState(() => _fajrBell = v),
          prayed: _fajrPrayed,
          onTogglePrayed: (v) => setState(() => _fajrPrayed = v),
        ),
        PrayerRow(
          icon: HayyaIcons.dhuhr,
          name: LocaleKeys.prayers_dhuhr.tr(),
          time: dhuhr.time,
          meridiem: dhuhr.meridiem,
          isCurrent: true,
          adhanOn: _dhuhrBell,
          onToggleAdhan: (v) => setState(() => _dhuhrBell = v),
          prayed: _dhuhrPrayed,
          onTogglePrayed: (v) => setState(() => _dhuhrPrayed = v),
        ),
        PrayerRow(
          icon: HayyaIcons.sunrise,
          name: LocaleKeys.prayers_sunrise.tr(),
          time: sunrise.time,
          meridiem: sunrise.meridiem,
          trackable: false,
          adhanOn: _sunriseBell,
          onToggleAdhan: (v) => setState(() => _sunriseBell = v),
        ),
      ],
    );
  }
}

class _TilesDemo extends StatelessWidget {
  const _TilesDemo();

  @override
  Widget build(BuildContext context) {
    const streak = 12;
    final stat = StatTile(
      icon: HayyaIcons.streak,
      tone: StatTone.gold,
      label: LocaleKeys.tracker_current_streak.tr(),
      value: NumberFormat.decimalPattern(context.locale.toString())
          .format(streak),
      unit: LocaleKeys.tracker_days.plural(streak),
    );
    final setting = SettingsTile(
      title: LocaleKeys.settings_calculation_method.tr(),
      subtitle: LocaleKeys.settings_method_egyptian.tr(),
      onTap: () {},
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 420
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: HayyaSpacing.s4,
              children: [
                Expanded(child: stat),
                Expanded(child: setting),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: HayyaSpacing.s4,
              children: [stat, setting],
            ),
    );
  }
}
