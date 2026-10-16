import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_radius.dart';
import '../theme/hayya_spacing.dart';
import '../theme/theme_context.dart';
import 'hayya_icon.dart';

enum HayyaButtonVariant {
  /// Filled primary — the one main action on a screen.
  primary,

  /// Primary-soft fill — secondary action ("Not now").
  soft,

  /// No fill — tertiary action ("Skip").
  text,

  /// Gold fill — tracker actions ("Log prayer").
  gold,
}

/// HayyaButton: 52 tall (taller when large text wraps the label), radius
/// lg, label 16/700.
/// Passing a null [onPressed] renders the disabled style.
class HayyaButton extends StatelessWidget {
  const HayyaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HayyaButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final HayyaButtonVariant variant;
  final HayyaIconData? icon;

  /// Stretch to the parent's width (full-width CTAs).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;

    final (Color bg, Color fg, double padding) = switch (variant) {
      _ when !enabled && variant == HayyaButtonVariant.text => (
        Colors.transparent,
        c.faint,
        14,
      ),
      _ when !enabled => (c.line, c.faint, 22),
      HayyaButtonVariant.primary => (c.primary, c.onPrimary, 24),
      HayyaButtonVariant.soft => (c.primarySoft, c.primaryInk, 22),
      HayyaButtonVariant.text => (Colors.transparent, c.primaryInk, 14),
      HayyaButtonVariant.gold => (c.gold, c.onGold, 20),
    };
    final radius = BorderRadius.circular(HayyaRadius.lg);

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            constraints: BoxConstraints(minHeight: 52.r),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: padding.r,
              vertical: HayyaSpacing.s2,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: HayyaSpacing.s2,
              children: [
                if (icon != null)
                  HayyaIcon(icon!, size: 20, color: fg, strokeWidth: 2.2),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.type
                        .style(16, FontWeight.w700, height: 1.2)
                        .copyWith(color: fg),
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

/// Round 48 px icon button with a hairline border (e.g. adhan notification).
class HayyaIconButton extends StatelessWidget {
  const HayyaIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final HayyaIconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: c.surface,
        shape: CircleBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 48.r,
            child: Center(
              child: HayyaIcon(
                icon,
                size: 22,
                color: onPressed == null ? c.faint : c.primaryInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
