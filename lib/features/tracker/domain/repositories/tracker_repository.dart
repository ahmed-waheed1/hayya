import '../../../prayer_times/domain/entities/prayer.dart';
import '../entities/tracker_data.dart';

/// Prayed prayers and the qada counter, stored only on this device.
abstract interface class TrackerRepository {
  TrackerData get data;

  /// Emits the new [data] after every change.
  Stream<TrackerData> get changes;

  /// Marks [prayer] on [day] as prayed or not.
  Future<void> setPrayed(DateTime day, Prayer prayer, {required bool prayed});

  /// Sets how many [prayer]s the user owes. Negative counts become zero.
  Future<void> setQadaOwed(Prayer prayer, int count);

  /// Logs one made-up [prayer]: one fewer owed. Does nothing when none
  /// are owed.
  Future<void> logQada(Prayer prayer);

  /// Takes back the last [logQada] for [prayer].
  Future<void> undoQada(Prayer prayer);
}
