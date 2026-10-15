import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 8-pt spacing scale from the design system, scaled with ScreenUtil.
///
/// Getters (not consts) because the scale factor is only known after
/// `ScreenUtilInit` has run.
abstract final class HayyaSpacing {
  static double get s1 => 4.r;
  static double get s2 => 8.r;
  static double get s3 => 12.r;
  static double get s4 => 16.r;
  static double get s5 => 20.r;
  static double get s6 => 24.r;
  static double get s8 => 32.r;
  static double get s12 => 48.r;

  static double get screenGutter => 20.r;
  static double get cardPadding => 20.r;
  static double get listRowHeight => 56.r;
  static double get sectionGap => 24.r;

  /// Accessibility floor; deliberately not scaled down on small phones.
  static const double minTouchTarget = 44;
}
