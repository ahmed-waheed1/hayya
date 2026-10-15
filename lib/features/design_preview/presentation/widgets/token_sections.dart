import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_colors.dart';
import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import 'preview_section.dart';

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

TextStyle _mono(BuildContext context) => TextStyle(
  fontFamily: 'monospace',
  fontSize: 12.sp,
  color: context.colors.muted,
);

class ColorSection extends StatelessWidget {
  const ColorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final swatches = [
      c.background, c.surface, c.surface2, c.line, c.text, c.muted, //
      c.primary, c.primaryInk, c.primarySoft, c.gold, c.goldInk, c.goldSoft,
    ];
    return PreviewSection(
      title: LocaleKeys.design_preview_colors.tr(),
      child: Wrap(
        spacing: HayyaSpacing.s3,
        runSpacing: HayyaSpacing.s3,
        children: [
          for (final color in swatches)
            SizedBox(
              width: 96.r,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: HayyaSpacing.s2,
                children: [
                  Container(
                    height: 56.r,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(HayyaRadius.md),
                      border: Border.all(color: c.line),
                    ),
                  ),
                  Text(_hex(color), style: _mono(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TimesOfDaySection extends StatelessWidget {
  const TimesOfDaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final periods = context.colors.periods;
    final samples = [
      (PrayerPeriod.fajr, LocaleKeys.prayers_fajr, 5, 28),
      (PrayerPeriod.dhuhr, LocaleKeys.prayers_dhuhr, 12, 39),
      (PrayerPeriod.maghrib, LocaleKeys.prayers_maghrib, 18, 25),
      (PrayerPeriod.isha, LocaleKeys.prayers_isha, 19, 42),
    ];
    return PreviewSection(
      title: LocaleKeys.design_preview_times_of_day.tr(),
      child: Wrap(
        spacing: HayyaSpacing.s4,
        runSpacing: HayyaSpacing.s4,
        children: [
          for (final (period, nameKey, h, m) in samples)
            Container(
              width: 160.r,
              height: 140.r,
              padding: EdgeInsetsDirectional.all(HayyaSpacing.s4),
              decoration: BoxDecoration(
                gradient: periods[period]!.gradient,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nameKey.tr(),
                    style: context.type.label.copyWith(
                      color: periods[period]!.ink,
                    ),
                  ),
                  Text(
                    formatSampleTime(context, h, m).time,
                    style: context.type
                        .style(30, FontWeight.w800, tabular: true)
                        .copyWith(color: periods[period]!.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class HeatmapSection extends StatelessWidget {
  const HeatmapSection({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = context.colors.heatmap;
    final number = NumberFormat.decimalPattern(context.locale.toString());
    return PreviewSection(
      title: LocaleKeys.design_preview_heatmap.tr(),
      child: Wrap(
        spacing: 6.r,
        children: [
          for (var i = 0; i < levels.length; i++)
            Column(
              spacing: 6.r,
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: levels[i],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                Text(number.format(i), style: _mono(context)),
              ],
            ),
        ],
      ),
    );
  }
}

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final t = formatSampleTime(context, 15, 58);
    final rows = [
      (type.timeDisplay, '${t.time} ${t.meridiem}'),
      (type.titleLarge, LocaleKeys.prayers_asr.tr()),
      (type.title, LocaleKeys.tracker_title.tr()),
      (type.body, LocaleKeys.onboarding_location_rationale.tr()),
      (type.label, LocaleKeys.prayers_mark_as_prayed.tr()),
      (type.overline, LocaleKeys.prayers_next_prayer.tr()),
    ];
    return PreviewSection(
      title: LocaleKeys.design_preview_typography.tr(),
      child: HayyaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: HayyaSpacing.s4,
          children: [
            for (final (style, text) in rows)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${style.fontSize!.round()} / '
                    '${(style.fontSize! * style.height!).round()} · '
                    '${style.fontWeight!.value}',
                    style: _mono(context),
                  ),
                  Text(text, style: style),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class SpacingRadiusSection extends StatelessWidget {
  const SpacingRadiusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spacing = [
      HayyaSpacing.s1, HayyaSpacing.s2, HayyaSpacing.s3, HayyaSpacing.s4, //
      HayyaSpacing.s5, HayyaSpacing.s6, HayyaSpacing.s8, HayyaSpacing.s12,
    ];
    final radii = [
      HayyaRadius.sm, HayyaRadius.md, HayyaRadius.lg, HayyaRadius.xl, //
      HayyaRadius.xxl, HayyaRadius.full,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PreviewSection(
          title: LocaleKeys.design_preview_spacing.tr(),
          child: HayyaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: HayyaSpacing.s3,
              children: [
                for (final v in spacing)
                  Row(
                    spacing: HayyaSpacing.s3,
                    children: [
                      Container(
                        width: v * 5,
                        height: 14.r,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Text(v.toStringAsFixed(0), style: _mono(context)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        PreviewSection(
          title: LocaleKeys.design_preview_radius.tr(),
          child: Wrap(
            spacing: HayyaSpacing.s4,
            runSpacing: HayyaSpacing.s4,
            children: [
              for (final r in radii)
                Container(
                  width: 96.r,
                  height: 72.r,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    border: Border.all(color: c.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(r),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ElevationSection extends StatelessWidget {
  const ElevationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewSection(
      title: LocaleKeys.design_preview_elevation.tr(),
      child: Container(
        padding: EdgeInsetsDirectional.all(HayyaSpacing.s6),
        decoration: BoxDecoration(
          color: context.colors.surface2,
          borderRadius: BorderRadius.circular(HayyaRadius.xl),
        ),
        child: Column(
          spacing: HayyaSpacing.s5,
          children: [
            for (final e in HayyaElevation.values)
              HayyaCard(
                elevation: e,
                child: SizedBox(height: 24.r, width: double.infinity),
              ),
          ],
        ),
      ),
    );
  }
}

class IconsSection extends StatelessWidget {
  const IconsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PreviewSection(
      title: LocaleKeys.design_preview_icons.tr(),
      child: Wrap(
        spacing: 10.r,
        runSpacing: 10.r,
        children: [
          for (final icon in HayyaIcons.all)
            Container(
              width: 52.r,
              height: 52.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(HayyaRadius.md),
              ),
              child: HayyaIcon(icon, size: 26, color: c.primaryInk),
            ),
        ],
      ),
    );
  }
}
