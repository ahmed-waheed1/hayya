import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme_context.dart';
import 'hayya_icon.dart';
import 'tap_target.dart';

/// "Prayed" check box. 30 px standalone, 26 px inside a [PrayerRow].
class PrayedCheck extends StatelessWidget {
  const PrayedCheck({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.size = 30,
    this.outlineColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  /// Box size in design px; radius and glyph scale with it.
  final double size;

  /// Unchecked border; defaults to faint.
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final compact = size < 30;
    return Semantics(
      checked: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: TapTarget(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size.r,
          height: size.r,
          decoration: BoxDecoration(
            color: value ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular((compact ? 9 : 10).r),
            border: value
                ? null
                : Border.all(color: outlineColor ?? c.faint, width: 2),
          ),
          child: value
              ? Center(
                  child: HayyaIcon(
                    HayyaIcons.check,
                    size: compact ? 16 : 18,
                    color: c.onPrimary,
                    strokeWidth: compact ? 2.8 : 2.6,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
