import 'package:easy_localization/easy_localization.dart';

import '../../../generated/locale_keys.g.dart';
import '../../prayer_times/domain/entities/prayer_calculation_settings.dart';

/// How a [CalculationMethod] is shown in Settings.
extension CalculationMethodDisplay on CalculationMethod {
  String get localizedName => switch (this) {
    CalculationMethod.muslimWorldLeague =>
      LocaleKeys.settings_methods_muslim_world_league_name,
    CalculationMethod.egyptian => LocaleKeys.settings_methods_egyptian_name,
    CalculationMethod.karachi => LocaleKeys.settings_methods_karachi_name,
    CalculationMethod.ummAlQura => LocaleKeys.settings_methods_umm_al_qura_name,
    CalculationMethod.dubai => LocaleKeys.settings_methods_dubai_name,
    CalculationMethod.moonsightingCommittee =>
      LocaleKeys.settings_methods_moonsighting_committee_name,
    CalculationMethod.northAmerica =>
      LocaleKeys.settings_methods_north_america_name,
    CalculationMethod.kuwait => LocaleKeys.settings_methods_kuwait_name,
    CalculationMethod.qatar => LocaleKeys.settings_methods_qatar_name,
    CalculationMethod.singapore => LocaleKeys.settings_methods_singapore_name,
    CalculationMethod.turkey => LocaleKeys.settings_methods_turkey_name,
    CalculationMethod.tehran => LocaleKeys.settings_methods_tehran_name,
  }.tr();

  /// Its angles and where it is used, with Latin digits; pass it through
  /// `LocalizedFormat.digits`.
  String get description => switch (this) {
    CalculationMethod.muslimWorldLeague =>
      LocaleKeys.settings_methods_muslim_world_league_description,
    CalculationMethod.egyptian =>
      LocaleKeys.settings_methods_egyptian_description,
    CalculationMethod.karachi =>
      LocaleKeys.settings_methods_karachi_description,
    CalculationMethod.ummAlQura =>
      LocaleKeys.settings_methods_umm_al_qura_description,
    CalculationMethod.dubai => LocaleKeys.settings_methods_dubai_description,
    CalculationMethod.moonsightingCommittee =>
      LocaleKeys.settings_methods_moonsighting_committee_description,
    CalculationMethod.northAmerica =>
      LocaleKeys.settings_methods_north_america_description,
    CalculationMethod.kuwait => LocaleKeys.settings_methods_kuwait_description,
    CalculationMethod.qatar => LocaleKeys.settings_methods_qatar_description,
    CalculationMethod.singapore =>
      LocaleKeys.settings_methods_singapore_description,
    CalculationMethod.turkey => LocaleKeys.settings_methods_turkey_description,
    CalculationMethod.tehran => LocaleKeys.settings_methods_tehran_description,
  }.tr();
}

extension HighLatitudeRuleDisplay on HighLatitudeRule {
  String get localizedName => switch (this) {
    HighLatitudeRule.middleOfTheNight =>
      LocaleKeys.settings_high_latitude_middle,
    HighLatitudeRule.seventhOfTheNight =>
      LocaleKeys.settings_high_latitude_seventh,
    HighLatitudeRule.twilightAngle => LocaleKeys.settings_high_latitude_angle,
  }.tr();

  String get description => switch (this) {
    HighLatitudeRule.middleOfTheNight =>
      LocaleKeys.settings_high_latitude_middle_sub,
    HighLatitudeRule.seventhOfTheNight =>
      LocaleKeys.settings_high_latitude_seventh_sub,
    HighLatitudeRule.twilightAngle =>
      LocaleKeys.settings_high_latitude_angle_sub,
  }.tr();
}
