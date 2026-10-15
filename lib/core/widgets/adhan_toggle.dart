import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_radius.dart';
import '../theme/theme_context.dart';
import 'hayya_icon.dart';

/// Adhan bell toggle: bell when on, crossed bell when off.
///
/// [filled] shows the 44 px primary-soft tile used on its own; inside a
/// [PrayerRow] the bell is drawn bare.
class AdhanToggle extends StatelessWidget {
  const AdhanToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.filled = true,
    this.iconSize = 22,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final bool filled;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(HayyaRadius.md);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: Material(
        color: filled && value ? c.primarySoft : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          borderRadius: radius,
          child: SizedBox.square(
            dimension: 44.r,
            child: Center(
              child: HayyaIcon(
                value ? HayyaIcons.bell : HayyaIcons.bellOff,
                size: iconSize,
                color: value ? c.primaryInk : c.faint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
