import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../domain/adhan_scheduler.dart';
import '../../domain/entities/adhan_preferences.dart';
import '../../domain/repositories/adhan_preferences_repository.dart';
import 'adhan_notifications_state.dart';

/// The adhan bells, the reminder and what the system allows.
///
/// Saving preferences is enough to reschedule: [AdhanScheduler] listens to
/// the repository.
class AdhanNotificationsCubit extends Cubit<AdhanNotificationsState> {
  AdhanNotificationsCubit({
    required this._repository,
    required this._notifications,
    required this._locationService,
    required this._scheduler,
  }) : super(AdhanNotificationsState(preferences: _repository.preferences));

  final AdhanPreferencesRepository _repository;
  final NotificationService _notifications;
  final LocationService _locationService;
  final AdhanScheduler _scheduler;

  StreamSubscription<Object?>? _firstLocation;
  bool _started = false;

  /// Reads the permissions, and on first run asks for notification
  /// permission once a location is known, so the prompt doesn't collide
  /// with the location prompt.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await refreshPermissions();
    if (_repository.permissionPrompted) return;
    if (_locationService.lastKnown != null) {
      await _promptOnce();
    } else {
      _firstLocation = _locationService.changes.take(1).listen((_) {
        _promptOnce();
      });
    }
  }

  /// Re-reads what the system allows, e.g. back from its settings.
  Future<void> refreshPermissions() async {
    final allowed = await _notifications.areNotificationsAllowed();
    final exact = await _notifications.canScheduleExact();
    if (isClosed) return;
    final gainedExact = exact && !state.exactAlarmsAllowed;
    emit(
      state.copyWith(notificationsAllowed: allowed, exactAlarmsAllowed: exact),
    );
    // Alarms set while exact ones were refused are inexact; redo them.
    if (gainedExact) await _scheduler.reschedule(force: true);
  }

  Future<void> setAdhan(Prayer prayer, {required bool on}) =>
      _save(state.preferences.withPrayer(prayer, on: on), turnedOn: on);

  Future<void> setReminderOn(bool on) =>
      _save(state.preferences.copyWith(reminderOn: on), turnedOn: on);

  Future<void> setReminderMinutes(int minutes) =>
      _save(state.preferences.copyWith(reminderMinutes: minutes));

  /// "Turn on" in Settings: the system prompt if it may still show,
  /// otherwise the app's notification settings.
  Future<void> allowNotifications() async {
    if (_repository.permissionPrompted) {
      await _notifications.openNotificationSettings();
    } else {
      await _request();
    }
    await refreshPermissions();
  }

  Future<void> allowExactAlarms() async {
    await _notifications.requestExactAlarms();
    await refreshPermissions();
  }

  Future<void> _save(
    AdhanPreferences preferences, {
    bool turnedOn = false,
  }) async {
    emit(state.copyWith(preferences: preferences));
    await _repository.save(preferences);
    // Turning something on is the moment the permission makes sense.
    if (turnedOn && !await _notifications.areNotificationsAllowed()) {
      await _request();
      await refreshPermissions();
    }
  }

  Future<void> _promptOnce() async {
    if (_repository.permissionPrompted || isClosed) return;
    if (state.preferences.enabled.isEmpty) return;
    await _request();
    await refreshPermissions();
  }

  Future<void> _request() async {
    await _repository.markPermissionPrompted();
    await _notifications.requestNotificationPermission();
  }

  @override
  Future<void> close() async {
    await _firstLocation?.cancel();
    return super.close();
  }
}
