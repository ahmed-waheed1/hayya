import '../entities/adhan_preferences.dart';

abstract interface class AdhanPreferencesRepository {
  AdhanPreferences get preferences;

  /// Emits each time [save] stores new preferences.
  Stream<AdhanPreferences> get changes;

  Future<void> save(AdhanPreferences preferences);

  /// Whether the app has already asked for notification permission on
  /// its own, so it never asks unprompted twice.
  bool get permissionPrompted;

  Future<void> markPermissionPrompted();
}
