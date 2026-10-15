import 'package:easy_localization/easy_localization.dart';

import '../../../core/utils/localized_format.dart';
import '../../../generated/locale_keys.g.dart';
import '../domain/qibla_direction.dart';

extension CompassPointLabel on CompassPoint {
  /// "SE" / "جنوب شرق".
  String get label => switch (this) {
    CompassPoint.n => LocaleKeys.compass_n,
    CompassPoint.ne => LocaleKeys.compass_ne,
    CompassPoint.e => LocaleKeys.compass_e,
    CompassPoint.se => LocaleKeys.compass_se,
    CompassPoint.s => LocaleKeys.compass_s,
    CompassPoint.sw => LocaleKeys.compass_sw,
    CompassPoint.w => LocaleKeys.compass_w,
    CompassPoint.nw => LocaleKeys.compass_nw,
  }.tr();
}

extension QiblaFormat on LocalizedFormat {
  /// Whole degrees from north, 0–359: "136°" / "١٣٦°".
  String degrees(double value) =>
      LocaleKeys.qibla_degrees.tr(args: [number(value.round() % 360)]);

  /// "1,287 km"; one decimal under 10 km ("1.1 km").
  String distanceKm(double km) => LocaleKeys.qibla_distance_value.tr(
    args: [grouped(km, fractionDigits: km < 10 ? 1 : 0)],
  );
}
