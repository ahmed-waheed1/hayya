import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_radius.dart';
import '../theme/theme_context.dart';
import 'tap_target.dart';

/// 52 × 32 pill switch. The thumb sits at the end edge when on, so it
/// mirrors in RTL.
class HayyaSwitch extends StatelessWidget {
  const HayyaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  static const _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: TapTarget(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOut,
          width: 52.r,
          height: 32.r,
          padding: EdgeInsetsDirectional.all(4.r),
          decoration: BoxDecoration(
            color: value ? c.primary : c.line,
            borderRadius: BorderRadius.circular(HayyaRadius.full),
          ),
          child: AnimatedAlign(
            duration: _duration,
            curve: Curves.easeOut,
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              width: 24.r,
              height: 24.r,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
