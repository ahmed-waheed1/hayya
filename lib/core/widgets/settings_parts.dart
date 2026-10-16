import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_spacing.dart';
import '../theme/theme_context.dart';
import 'adaptive_row.dart';
import 'hayya_icon.dart';
import 'hayya_radio.dart';

/// A group's overline title ("GENERAL") above its card.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.child});

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
          child: Semantics(
            header: true,
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
        ),
        child,
      ],
    );
  }
}

/// The 32 px rounded square behind a row's icon.
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge(this.icon, {super.key});

  final HayyaIconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 32.r,
      height: 32.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: HayyaIcon(icon, size: 18, color: c.primaryInk, strokeWidth: 1.9),
    );
  }
}

/// Title and optional subtitle, as in every settings row.
class SettingsLabel extends StatelessWidget {
  const SettingsLabel({
    super.key,
    required this.title,
    this.subtitle,
    this.selected = false,
  });

  final String title;
  final String? subtitle;

  /// Bolder title, for the chosen row of a radio list.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 2.r,
      children: [
        Text(
          title,
          style: type
              .style(15, selected ? FontWeight.w800 : FontWeight.w700)
              .copyWith(color: c.text),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: type.style(12.5, FontWeight.w600).copyWith(color: c.muted),
          ),
      ],
    );
  }
}

/// Icon (optional) + label, with the segmented picker on its own line
/// below.
class SettingsPickerRow extends StatelessWidget {
  const SettingsPickerRow({
    super.key,
    this.icon,
    required this.label,
    required this.picker,
  });

  final HayyaIconData? icon;
  final String label;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: HayyaSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10.r,
        children: [
          Row(
            spacing: 10.r,
            children: [
              if (icon case final icon?) SettingsIconBadge(icon),
              Expanded(child: SettingsLabel(title: label)),
            ],
          ),
          picker,
        ],
      ),
    );
  }
}

/// Label, then − value + (Manual adjustments, Hijri date). The buttons
/// disable at the ends of the range.
class SettingsStepperRow extends StatelessWidget {
  const SettingsStepperRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.highlighted,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String? subtitle;
  final String value;

  /// Not at the default; the value is drawn in the primary ink.
  final bool highlighted;
  final String decreaseLabel;
  final String increaseLabel;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 56.r),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: HayyaSpacing.s1),
        // With large text the − value + controls move under the label.
        child: AdaptiveRow(
          gap: HayyaSpacing.s2,
          label: SettingsLabel(title: label, subtitle: subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: HayyaSpacing.s2,
            children: [
              _StepButton(
                icon: HayyaIcons.minus,
                semanticLabel: decreaseLabel,
                onTap: onDecrease,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 64.r),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: context.type
                      .style(15, FontWeight.w800)
                      .copyWith(
                        color: highlighted ? c.primaryInk : c.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
              _StepButton(
                icon: HayyaIcons.add,
                semanticLabel: increaseLabel,
                onTap: onIncrease,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final HayyaIconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12.r);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: c.surface2,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: HayyaSpacing.minTouchTarget,
            child: Center(
              child: HayyaIcon(
                icon,
                size: 18,
                color: onTap == null ? c.faint : c.text,
                strokeWidth: 2.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One choice in a radio list: dot, title and subtitle. The whole row is
/// the tap target.
class SettingsRadioRow extends StatelessWidget {
  const SettingsRadioRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 54.r),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: 6.r),
            child: Row(
              spacing: HayyaSpacing.s3,
              children: [
                ExcludeSemantics(
                  child: HayyaRadio(selected: selected, onTap: null),
                ),
                Expanded(
                  child: SettingsLabel(
                    title: title,
                    subtitle: subtitle,
                    selected: selected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
