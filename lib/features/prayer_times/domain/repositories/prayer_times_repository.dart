import '../../../../core/services/user_location.dart';
import '../entities/prayer_calculation_settings.dart';
import '../entities/prayer_day.dart';

abstract interface class PrayerTimesRepository {
  /// The six times on [date] at [coordinates], in the device's time zone.
  PrayerDay timesFor(
    DateTime date,
    GeoCoordinates coordinates,
    PrayerCalculationSettings settings,
  );
}
