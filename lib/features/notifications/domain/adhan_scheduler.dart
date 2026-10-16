import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../prayer_times/domain/entities/prayer.dart';
import '../../prayer_times/domain/repositories/prayer_settings_repository.dart';
import 'entities/adhan_preferences.dart';
import 'entities/planned_notification.dart';
import 'repositories/adhan_preferences_repository.dart';
import 'usecases/plan_adhan_notifications.dart';

/// Notification text in the app's current language.
abstract interface class NotificationTexts {
  ({String title, String body}) forNotification(PlannedNotification n);

  ChannelLabel channel(NotificationSound sound);
}

/// Keeps the pending adhan notifications in step with the plan.
///
/// Nothing is scheduled until [useTexts] supplies the app's language.
/// After [start] it reschedules on its own when the location, the
/// calculation settings or the adhan preferences (including the volume,
/// which picks the adhan's channel) change. The app also
/// calls [reschedule] on open and on resume, and [useTexts] after a
/// language change.
class AdhanScheduler {
  AdhanScheduler({
    required this._locationService,
    required this._settingsRepository,
    required this._preferencesRepository,
    required this._notifications,
    required this._plan,
    this._clock = DateTime.now,
  });

  final LocationService _locationService;
  final PrayerSettingsRepository _settingsRepository;
  final AdhanPreferencesRepository _preferencesRepository;
  final NotificationService _notifications;
  final PlanAdhanNotifications _plan;
  final DateTime Function() _clock;
  NotificationTexts? _texts;

  final _subscriptions = <StreamSubscription<Object?>>[];
  Future<void>? _running;
  bool _again = false;
  bool _force = false;

  /// What was last handed to the system; an identical plan with the same
  /// channel names is skipped.
  List<ScheduledNotification>? _applied;
  Map<NotificationSound, ChannelLabel>? _appliedChannels;

  /// When the debug test adhan is due, until it has fired.
  DateTime? _testAt;

  /// Id of the test adhan. Planned ids start at 20 (day 1 × 20), so this
  /// never collides.
  static const testId = 1;

  /// Subscribes to the triggers. Safe to call more than once.
  void start() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions.addAll([
      _locationService.changes.listen((_) => reschedule()),
      _settingsRepository.changes.listen((_) => reschedule()),
      _preferencesRepository.changes.listen((_) => reschedule()),
    ]);
  }

  /// Writes notifications with [texts] from now on, and reschedules so
  /// pending ones switch language too.
  Future<void> useTexts(NotificationTexts texts) {
    _texts = texts;
    return reschedule();
  }

  /// Debug aid: an adhan [delay] from now on the real channel and sound.
  ///
  /// It is kept in the pending set until it fires, so a reschedule in the
  /// meantime (e.g. on resume) doesn't cancel it.
  Future<void> scheduleTest({Duration delay = const Duration(minutes: 1)}) {
    _testAt = _clock().add(delay);
    return reschedule();
  }

  /// Plans and applies. A call made while one is running is folded into a
  /// single follow-up run; the returned future completes after it.
  ///
  /// [force] applies the plan even if it hasn't changed, e.g. to upgrade
  /// inexact alarms once exact ones are allowed.
  Future<void> reschedule({bool force = false}) {
    _force |= force;
    if (_running case final running?) {
      _again = true;
      return running;
    }
    return _running = _run();
  }

  Future<void> _run() async {
    try {
      do {
        _again = false;
        await _apply();
      } while (_again);
    } finally {
      _running = null;
    }
  }

  Future<void> _apply() async {
    final texts = _texts;
    if (texts == null) return;
    try {
      final now = _clock();
      final testAt = _testAt;
      if (testAt != null && !testAt.isAfter(now)) _testAt = null;
      final location = _locationService.lastKnown;
      final preferences = _preferencesRepository.preferences;
      final planned = location == null
          ? const <PlannedNotification>[]
          : _plan(
              now: now,
              coordinates: location.coordinates,
              settings: _settingsRepository.settings,
              preferences: preferences,
              // Leave room for the test adhan under iOS's cap.
              limit: _notifications.maxPending - (_testAt == null ? 0 : 1),
              days: _notifications.planDays,
            );
      final scheduled = [
        for (final n in planned)
          if (texts.forNotification(n) case (:final title, :final body))
            ScheduledNotification(
              id: n.id,
              at: n.at,
              title: title,
              body: body,
              sound: _soundFor(n.kind, preferences.volume),
            ),
        if (_testAt case final at?)
          if (texts.forNotification(
                PlannedNotification(
                  prayer: planned.firstOrNull?.prayer ?? Prayer.fajr,
                  kind: NotificationKind.adhan,
                  prayerTime: at,
                  at: at,
                ),
              )
              case (:final title, :final body))
            ScheduledNotification(
              id: testId,
              at: at,
              title: title,
              body: body,
              sound: _soundFor(NotificationKind.adhan, preferences.volume),
            ),
      ];
      final channels = {
        for (final sound in NotificationSound.values)
          sound: texts.channel(sound),
      };
      // Channel names count too: after a language change with nothing to
      // schedule, they still need renaming.
      if (!_force &&
          listEquals(scheduled, _applied) &&
          mapEquals(channels, _appliedChannels)) {
        return;
      }
      _force = false;

      await _notifications.replacePending(scheduled, channels: channels);
      _applied = scheduled;
      _appliedChannels = channels;
    } on Object catch (e, stack) {
      // Never let a platform failure break the app; the next trigger
      // tries again.
      _applied = null;
      _appliedChannels = null;
      debugPrint('Scheduling adhan notifications failed: $e\n$stack');
    }
  }

  /// The adhan's channel follows the volume choice, since Android fixes a
  /// channel's audio stream when it is created.
  static NotificationSound _soundFor(
    NotificationKind kind,
    AdhanVolume volume,
  ) => switch ((kind, volume)) {
    (NotificationKind.adhan, AdhanVolume.alarm) => NotificationSound.adhan,
    (NotificationKind.adhan, AdhanVolume.notification) =>
      NotificationSound.adhanNotificationVolume,
    (NotificationKind.reminder, _) => NotificationSound.reminder,
  };

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }
}
