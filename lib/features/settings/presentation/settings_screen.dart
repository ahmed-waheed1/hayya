import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/preferences/language_switcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/hayya_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/theme_mode_cubit.dart';
import '../../../core/widgets/widgets.dart';
import '../../../generated/locale_keys.g.dart';
import '../../notifications/domain/adhan_scheduler.dart';
import '../../notifications/presentation/widgets/notification_settings_group.dart';

/// Settings, so far the "General" (language, theme) and "Notifications"
/// groups from the design. The other groups come with their features.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            HayyaSpacing.s4,
            HayyaSpacing.s4,
            HayyaSpacing.s4,
            HayyaSpacing.s8,
          ),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: HayyaSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: HayyaSpacing.s1,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    LocaleKeys.settings_title.tr(),
                    style: type
                        .style(26, FontWeight.w800)
                        .copyWith(color: context.colors.text),
                  ),
                ),
              ),
            ),
            SizedBox(height: 22.r),
            _Section(
              title: LocaleKeys.settings_general.tr(),
              child: const _GeneralGroup(),
            ),
            SizedBox(height: 22.r),
            _Section(
              title: LocaleKeys.settings_notifications.tr(),
              child: const NotificationSettingsGroup(),
            ),
            if (kDebugMode) ...[
              SizedBox(height: 22.r),
              _Section(
                title: LocaleKeys.settings_developer.tr(),
                child: Column(
                  spacing: HayyaSpacing.s2,
                  children: [
                    SettingsTile(
                      title: LocaleKeys.design_preview_title.tr(),
                      onTap: () => context.push(AppRoutes.designPreview),
                    ),
                    SettingsTile(
                      title: LocaleKeys.settings_test_adhan.tr(),
                      onTap: () => _testAdhan(context),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HayyaSpacing.s2,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: HayyaSpacing.s2),
          child: Text(
            title,
            style: type
                .style(
                  13,
                  FontWeight.w800,
                  trackingEm: 0.08,
                  height: type.isArabic ? 1.5 : 1.25,
                )
                .copyWith(color: context.colors.muted),
          ),
        ),
        child,
      ],
    );
  }
}

class _GeneralGroup extends StatelessWidget {
  const _GeneralGroup();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return HayyaCard(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 14.r, vertical: 6.r),
      child: Column(
        children: [
          _PickerRow(
            icon: HayyaIcons.language,
            label: LocaleKeys.settings_language.tr(),
            picker: SegmentedPicker<String>(
              options: [
                SegmentOption(
                  value: 'en',
                  label: LocaleKeys.settings_language_english.tr(),
                ),
                SegmentOption(
                  value: 'ar',
                  label: LocaleKeys.settings_language_arabic.tr(),
                ),
              ],
              value: context.locale.languageCode,
              onChanged: context.switchLanguage,
            ),
          ),
          Divider(color: c.line),
          _PickerRow(
            icon: HayyaIcons.theme,
            label: LocaleKeys.settings_theme.tr(),
            picker: BlocBuilder<ThemeModeCubit, ThemeMode>(
              builder: (context, mode) => SegmentedPicker<ThemeMode>(
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
                value: mode,
                onChanged: context.read<ThemeModeCubit>().setMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon + label, with the segmented picker on its own line below.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.picker,
  });

  final HayyaIconData icon;
  final String label;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: HayyaSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.r,
        children: [
          Row(
            spacing: 10.r,
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: HayyaIcon(
                  icon,
                  size: 18,
                  color: c.primaryInk,
                  strokeWidth: 1.9,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: context.type
                      .style(15, FontWeight.w700)
                      .copyWith(color: c.text),
                ),
              ),
            ],
          ),
          picker,
        ],
      ),
    );
  }
}
