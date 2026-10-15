import 'package:flutter/material.dart';

import 'hayya_colors.dart';
import 'hayya_typography.dart';

extension HayyaThemeContext on BuildContext {
  HayyaColors get colors => Theme.of(this).extension<HayyaColors>()!;

  HayyaTypography get type => Theme.of(this).extension<HayyaTypography>()!;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
