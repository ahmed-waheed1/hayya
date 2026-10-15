import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../calculation_display.dart';
import '../cubit/prayer_settings_cubit.dart';

/// Every calculation method with its angles, the one suggested for the
/// user's country first. Picking one saves it and closes the sheet.
///
/// Not in the design, which only shows the row that opens it.
Future<void> showCalculationMethodSheet(BuildContext context) {
  final cubit = context.read<PrayerSettingsCubit>();
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.surface,
    // Tablets: a sheet as wide as a phone column, not the whole screen.
    constraints: const BoxConstraints(maxWidth: 640),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(HayyaRadius.xxl),
      ),
    ),
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _MethodSheet()),
  );
}

class _MethodSheet extends StatelessWidget {
  const _MethodSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final format = context.format;
    final state = context.watch<PrayerSettingsCubit>().state;
    final suggested = state.suggestedMethod;
    final country = state.location
        ?.placeName(context.locale.languageCode)
        ?.country;
    final methods = [
      ?suggested,
      for (final m in CalculationMethod.values)
        if (m != suggested) m,
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: EdgeInsetsDirectional.only(top: 10.r),
              width: 40.r,
              height: 4.r,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(HayyaRadius.full),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20.r, 14.r, 20.r, 6.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.r,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    LocaleKeys.settings_calculation_method.tr(),
                    style: type
                        .style(20, FontWeight.w800)
                        .copyWith(color: c.text),
                  ),
                ),
                Text(
                  LocaleKeys.settings_method_sheet_hint.tr(),
                  style: type
                      .style(13, FontWeight.w600)
                      .copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsetsDirectional.fromSTEB(
                14.r,
                0,
                14.r,
                HayyaSpacing.s4,
              ),
              children: [
                for (final method in methods)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsRadioRow(
                        title: method.localizedName,
                        subtitle: format.digits(method.description),
                        selected: method == state.settings.method,
                        onTap: () {
                          context.read<PrayerSettingsCubit>().setMethod(method);
                          Navigator.of(context).pop();
                        },
                      ),
                      if (method == suggested)
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: 34.r,
                            bottom: HayyaSpacing.s2,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _SuggestedChip(
                              label: country == null
                                  ? LocaleKeys.settings_method_suggested.tr()
                                  : LocaleKeys.settings_method_suggested_for.tr(
                                      args: [country],
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedChip extends StatelessWidget {
  const _SuggestedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.r, vertical: 3.r),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(HayyaRadius.full),
      ),
      child: Text(
        label,
        style: context.type
            .style(12, FontWeight.w800)
            .copyWith(color: c.primaryInk),
      ),
    );
  }
}
