import '../../../../core/services/location_service.dart';
import '../../../prayer_times/domain/repositories/prayer_settings_repository.dart';
import '../../../prayer_times/domain/usecases/get_prayer_schedule.dart';
import '../entities/tracking_position.dart';

/// The current prayer day, from today's times at the last known location.
/// Without a location it falls back to the calendar date.
class GetTrackingPosition {
  GetTrackingPosition({
    required this._locationService,
    required this._settingsRepository,
    required this._getSchedule,
    this._clock = DateTime.now,
  });

  final LocationService _locationService;
  final PrayerSettingsRepository _settingsRepository;
  final GetPrayerSchedule _getSchedule;
  final DateTime Function() _clock;

  TrackingPosition call() {
    final now = _clock();
    final location = _locationService.lastKnown;
    if (location == null) return TrackingPosition(day: now);
    return TrackingPosition.of(
      _getSchedule(
        now: now,
        coordinates: location.coordinates,
        settings: _settingsRepository.settings,
      ),
    );
  }
}
