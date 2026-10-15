// TEMPORARY: design-system preview for comparing against the design export.
// Delete this feature folder (and its route) once real screens exist.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/preferences/language_switcher.dart';
import '../../../core/theme/hayya_spacing.dart';
import '../../../core/theme/theme_mode_cubit.dart';
import '../../../core/widgets/widgets.dart';
import '../../../generated/locale_keys.g.dart';
import 'widgets/components_panel.dart';
import 'widgets/preview_section.dart';
import 'widgets/token_sections.dart';

class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.design_preview_title.tr())),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            HayyaSpacing.screenGutter,
            HayyaSpacing.s2,
            HayyaSpacing.screenGutter,
            HayyaSpacing.s12,
          ),
          children: [
            const _PreviewControls(),
            SizedBox(height: HayyaSpacing.s8),
            const ColorSection(),
            const TimesOfDaySection(),
            const HeatmapSection(),
            const TypographySection(),
            const SpacingRadiusSection(),
            const ElevationSection(),
            PreviewSection(
              title: LocaleKeys.design_preview_components.tr(),
              child: const ComponentsPanels(),
            ),
            const IconsSection(),
          ],
        ),
      ),
    );
  }
}

/// Language + theme switches. The component panels below always render
/// both light and dark; these switches drive the rest of the page.
class _PreviewControls extends StatelessWidget {
  const _PreviewControls();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: HayyaSpacing.s3,
      runSpacing: HayyaSpacing.s3,
      children: [
        SegmentedPicker<String>(
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
        BlocBuilder<ThemeModeCubit, ThemeMode>(
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
      ],
    );
  }
}
