import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme_context.dart';
import 'tap_target.dart';

/// 22 px radio dot.
class HayyaRadio extends StatelessWidget {
  const HayyaRadio({
    super.key,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primaryInk : c.faint;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: semanticLabel,
      child: TapTarget(
        onTap: onTap,
        child: Container(
          width: 22.r,
          height: 22.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: selected ? 1 : 0,
            duration: const Duration(milliseconds: 140),
            child: Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
