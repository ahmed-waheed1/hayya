import '../entities/prayer_calculation_settings.dart';

/// The method most mosques and official timetables use in a country.
///
/// [countryCode] is ISO 3166-1 alpha-2 ("EG"), any case. Null when the
/// country isn't known (offline on the first fix), so nothing is
/// suggested. Countries without a well-known convention get the Muslim
/// World League, the most widely used default.
CalculationMethod? suggestCalculationMethod(String? countryCode) {
  if (countryCode == null || countryCode.trim().isEmpty) return null;
  return _byCountry[countryCode.trim().toUpperCase()] ??
      CalculationMethod.muslimWorldLeague;
}

const _byCountry = {
  // Egyptian General Authority of Survey: Egypt and much of the Levant
  // and North-East Africa.
  'EG': CalculationMethod.egyptian,
  'SD': CalculationMethod.egyptian,
  'SS': CalculationMethod.egyptian,
  'LY': CalculationMethod.egyptian,
  'SY': CalculationMethod.egyptian,
  'LB': CalculationMethod.egyptian,
  'PS': CalculationMethod.egyptian,
  'JO': CalculationMethod.egyptian,
  'IQ': CalculationMethod.egyptian,
  'SA': CalculationMethod.ummAlQura,
  'YE': CalculationMethod.ummAlQura,
  'AE': CalculationMethod.dubai,
  'BH': CalculationMethod.dubai,
  'OM': CalculationMethod.dubai,
  'KW': CalculationMethod.kuwait,
  'QA': CalculationMethod.qatar,
  'PK': CalculationMethod.karachi,
  'IN': CalculationMethod.karachi,
  'BD': CalculationMethod.karachi,
  'AF': CalculationMethod.karachi,
  'SG': CalculationMethod.singapore,
  'MY': CalculationMethod.singapore,
  'ID': CalculationMethod.singapore,
  'BN': CalculationMethod.singapore,
  'TR': CalculationMethod.turkey,
  'IR': CalculationMethod.tehran,
  'US': CalculationMethod.northAmerica,
  'CA': CalculationMethod.northAmerica,
  'GB': CalculationMethod.moonsightingCommittee,
  'IE': CalculationMethod.moonsightingCommittee,
};
