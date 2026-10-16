import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_spacing.dart';
import '../theme/theme_context.dart';
import 'hayya_icon.dart';

/// A 44 × 44 icon button: plain (a back button on a title row) or on a
/// [surface2] fill ([filled]).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final HayyaIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular((filled ? 12 : 14).r);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled ? c.surface2 : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: math.max(HayyaSpacing.minTouchTarget, 44.r),
            child: Center(
              child: HayyaIcon(
                icon,
                size: filled ? 20 : 22,
                strokeWidth: filled ? 2.2 : 2,
                color: c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
