import 'package:adhan/adhan.dart' as adhan;

import '../../../core/services/user_location.dart';
import '../domain/entities/prayer.dart';
import '../domain/entities/prayer_calculation_settings.dart';
import '../domain/entities/prayer_day.dart';
import '../domain/repositories/prayer_times_repository.dart';

/// Calculates times offline with the adhan package.
class AdhanPrayerTimesRepository implements PrayerTimesRepository {
  const AdhanPrayerTimesRepository();

  @override
  PrayerDay timesFor(
    DateTime date,
    GeoCoordinates coordinates,
    PrayerCalculationSettings settings,
  ) {
    final params = _method(settings.method).getParameters()
      ..madhab = _madhab(settings.madhab)
      ..highLatitudeRule = _highLatitudeRule(settings.highLatitudeRule)
      // Added to the method's own adjustments, not instead of them.
      ..adjustments = adhan.PrayerAdjustments(
        fajr: settings.adjustmentFor(Prayer.fajr),
        sunrise: settings.adjustmentFor(Prayer.sunrise),
        dhuhr: settings.adjustmentFor(Prayer.dhuhr),
        asr: settings.adjustmentFor(Prayer.asr),
        maghrib: settings.adjustmentFor(Prayer.maghrib),
        isha: settings.adjustmentFor(Prayer.isha),
      );
    final times = adhan.PrayerTimes(
      adhan.Coordinates(coordinates.latitude, coordinates.longitude),
      adhan.DateComponents(date.year, date.month, date.day),
      params,
    );
    // adhan returns device-local times, rounded to the minute.
    return PrayerDay(
      date: date,
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
    );
  }

  static adhan.CalculationMethod _method(CalculationMethod method) =>
      switch (method) {
        CalculationMethod.muslimWorldLeague =>
          adhan.CalculationMethod.muslim_world_league,
        CalculationMethod.egyptian => adhan.CalculationMethod.egyptian,
        CalculationMethod.karachi => adhan.CalculationMethod.karachi,
        CalculationMethod.ummAlQura => adhan.CalculationMethod.umm_al_qura,
        CalculationMethod.dubai => adhan.CalculationMethod.dubai,
        CalculationMethod.moonsightingCommittee =>
          adhan.CalculationMethod.moon_sighting_committee,
        CalculationMethod.northAmerica => adhan.CalculationMethod.north_america,
        CalculationMethod.kuwait => adhan.CalculationMethod.kuwait,
        CalculationMethod.qatar => adhan.CalculationMethod.qatar,
        CalculationMethod.singapore => adhan.CalculationMethod.singapore,
        CalculationMethod.turkey => adhan.CalculationMethod.turkey,
        CalculationMethod.tehran => adhan.CalculationMethod.tehran,
      };

  static adhan.Madhab _madhab(AsrMadhab madhab) => switch (madhab) {
    AsrMadhab.shafi => adhan.Madhab.shafi,
    AsrMadhab.hanafi => adhan.Madhab.hanafi,
  };

  static adhan.HighLatitudeRule _highLatitudeRule(HighLatitudeRule rule) =>
      switch (rule) {
        HighLatitudeRule.middleOfTheNight =>
          adhan.HighLatitudeRule.middle_of_the_night,
        HighLatitudeRule.seventhOfTheNight =>
          adhan.HighLatitudeRule.seventh_of_the_night,
        HighLatitudeRule.twilightAngle => adhan.HighLatitudeRule.twilight_angle,
      };
}
