import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/preferences/display_preferences.dart';
import '../../../../core/preferences/language_switcher.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/theme_mode_cubit.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';

/// Settings → General: language, theme, numerals (Arabic only) and the
/// clock.
class GeneralGroup extends StatelessWidget {
  const GeneralGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final display = context.watch<DisplayPreferencesCubit>();
    final format = context.format;
    final divider = Divider(color: c.line);
    return HayyaCard(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 14.r, vertical: 6.r),
      child: Column(
        children: [
          SettingsPickerRow(
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
          divider,
          SettingsPickerRow(
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
          // The design also shows this in English, where it would change
          // nothing: English always uses Western digits.
          if (context.locale.languageCode == 'ar') ...[
            divider,
            SettingsPickerRow(
              icon: HayyaIcons.numerals,
              label: LocaleKeys.settings_numerals.tr(),
              picker: SegmentedPicker<Numerals>(
                options: [
                  SegmentOption(
                    value: Numerals.arabicIndic,
                    label: LocaleKeys.settings_numerals_arabic.tr(),
                  ),
                  SegmentOption(
                    value: Numerals.western,
                    label: LocaleKeys.settings_numerals_western.tr(),
                  ),
                ],
                value: display.state.numerals,
                onChanged: display.setNumerals,
              ),
            ),
          ],
          divider,
          SettingsPickerRow(
            icon: HayyaIcons.reminder,
            label: LocaleKeys.settings_time_format.tr(),
            picker: SegmentedPicker<TimeFormat>(
              options: [
                SegmentOption(
                  value: TimeFormat.twelveHour,
                  label: LocaleKeys.settings_time_hours.tr(
                    args: [format.number(12)],
                  ),
                ),
                SegmentOption(
                  value: TimeFormat.twentyFourHour,
                  label: LocaleKeys.settings_time_hours.tr(
                    args: [format.number(24)],
                  ),
                ),
              ],
              // Until picked, the device's setting shows as chosen.
              value: format.use24Hour
                  ? TimeFormat.twentyFourHour
                  : TimeFormat.twelveHour,
              onChanged: display.setTimeFormat,
            ),
          ),
        ],
      ),
    );
  }
}
