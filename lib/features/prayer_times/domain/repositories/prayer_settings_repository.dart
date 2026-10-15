import '../entities/prayer_calculation_settings.dart';

abstract interface class PrayerSettingsRepository {
  PrayerCalculationSettings get settings;

  /// Emits each time [save] stores new settings.
  Stream<PrayerCalculationSettings> get changes;

  Future<void> save(PrayerCalculationSettings settings);
}
