import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/repositories/hijri_calendar_repository.dart';
import '../../../prayer_times/presentation/prayer_display.dart';
import '../calculation_display.dart';
import '../cubit/prayer_settings_cubit.dart';
import 'calculation_method_sheet.dart';

/// Settings → Prayer times: method, Asr, the high-latitude rule (far
/// from the equator only) and the Hijri date.
///
/// Needs a [PrayerSettingsCubit] above it.
class PrayerTimesGroup extends StatelessWidget {
  const PrayerTimesGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final format = context.format;
    final cubit = context.read<PrayerSettingsCubit>();
    final state = context.watch<PrayerSettingsCubit>().state;
    final settings = state.settings;
    final divider = Divider(color: c.line, height: 1);
    final hijri = state.hijriAdjustmentDays;

    return HayyaCard(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 14.r, vertical: 6.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MethodTile(
            method: settings.method,
            onTap: () => showCalculationMethodSheet(context),
          ),
          divider,
          SettingsPickerRow(
            label: LocaleKeys.settings_asr_calculation.tr(),
            picker: SegmentedPicker<AsrMadhab>(
              options: [
                SegmentOption(
                  value: AsrMadhab.shafi,
                  label: LocaleKeys.settings_madhab_shafi.tr(),
                  sublabel: LocaleKeys.settings_madhab_shafi_sub.tr(),
                ),
                SegmentOption(
                  value: AsrMadhab.hanafi,
                  label: LocaleKeys.settings_madhab_hanafi.tr(),
                  sublabel: LocaleKeys.settings_madhab_hanafi_sub.tr(),
                ),
              ],
              value: settings.madhab,
              onChanged: cubit.setMadhab,
            ),
          ),
          if (state.showsHighLatitudeRule) ...[
            divider,
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: HayyaSpacing.s3,
                bottom: HayyaSpacing.s1,
              ),
              child: SettingsLabel(
                title: LocaleKeys.settings_high_latitude.tr(),
                subtitle: LocaleKeys.settings_high_latitude_sub.tr(),
              ),
            ),
            for (final rule in HighLatitudeRule.values)
              SettingsRadioRow(
                title: rule.localizedName,
                subtitle: rule.description,
                selected: rule == settings.highLatitudeRule,
                onTap: () => cubit.setHighLatitudeRule(rule),
              ),
            SizedBox(height: HayyaSpacing.s1),
          ],
          divider,
          Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: 6.r),
            child: SettingsStepperRow(
              label: LocaleKeys.settings_hijri_date.tr(),
              subtitle: LocaleKeys.settings_hijri_today.tr(
                args: [state.hijriToday.format(format)],
              ),
              value: format.digits(
                LocaleKeys.settings_hijri_days.plural(
                  hijri.abs(),
                  args: [format.signed(hijri)],
                ),
              ),
              highlighted: hijri != 0,
              decreaseLabel: LocaleKeys.settings_hijri_earlier.tr(),
              increaseLabel: LocaleKeys.settings_hijri_later.tr(),
              onDecrease: hijri > -maxAdjustmentDays
                  ? () => cubit.adjustHijri(-1)
                  : null,
              onIncrease: hijri < maxAdjustmentDays
                  ? () => cubit.adjustHijri(1)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.onTap});

  final CalculationMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 64.r),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: HayyaSpacing.s2),
            child: Row(
              spacing: 10.r,
              children: [
                const SettingsIconBadge(HayyaIcons.reminder),
                Expanded(
                  child: SettingsLabel(
                    title: LocaleKeys.settings_calculation_method.tr(),
                    subtitle: method.localizedName,
                  ),
                ),
                HayyaIcon(
                  HayyaIcons.chevron,
                  size: 18,
                  color: c.faint,
                  strokeWidth: 2.2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings → Manual adjustments (minutes): −30 to +30 for each time.
class AdjustmentsGroup extends StatelessWidget {
  const AdjustmentsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final format = context.format;
    final cubit = context.read<PrayerSettingsCubit>();
    final settings = context
        .select<PrayerSettingsCubit, PrayerCalculationSettings>(
          (cubit) => cubit.state.settings,
        );
    const max = PrayerCalculationSettings.maxAdjustment;
    return HayyaCard(
      padding: EdgeInsetsDirectional.fromSTEB(14.r, 4.r, 8.r, 4.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, prayer) in Prayer.values.indexed) ...[
            if (i > 0) Divider(color: c.line, height: 1),
            SettingsStepperRow(
              label: prayer.localizedName,
              value: LocaleKeys.settings_adjust_minutes.tr(
                args: [format.signed(settings.adjustmentFor(prayer))],
              ),
              highlighted: settings.adjustmentFor(prayer) != 0,
              decreaseLabel: LocaleKeys.settings_adjust_earlier.tr(
                args: [prayer.localizedName],
              ),
              increaseLabel: LocaleKeys.settings_adjust_later.tr(
                args: [prayer.localizedName],
              ),
              onDecrease: settings.adjustmentFor(prayer) > -max
                  ? () => cubit.adjust(prayer, -1)
                  : null,
              onIncrease: settings.adjustmentFor(prayer) < max
                  ? () => cubit.adjust(prayer, 1)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
