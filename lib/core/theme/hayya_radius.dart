import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Corner radii from the design system, scaled with ScreenUtil.
abstract final class HayyaRadius {
  /// Checkbox, chips.
  static double get sm => 10.r;

  /// Rows, controls.
  static double get md => 14.r;

  /// Buttons, inputs.
  static double get lg => 16.r;

  /// Cards.
  static double get xl => 20.r;

  /// Sheets, hero.
  static double get xxl => 28.r;

  /// Pills, nav.
  static const double full = 999;
}
