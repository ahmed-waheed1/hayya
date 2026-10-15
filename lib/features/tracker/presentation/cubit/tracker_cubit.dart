import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../prayer_times/domain/entities/prayer.dart';
import '../../domain/entities/tracker_data.dart';
import '../../domain/repositories/tracker_repository.dart';

/// App-wide tracker data: Home marks prayers, the Tracker screen shows
/// and edits them. Lives as long as the app.
class TrackerCubit extends Cubit<TrackerData> {
  TrackerCubit(this._repository) : super(_repository.data) {
    _subscription = _repository.changes.listen(emit);
  }

  final TrackerRepository _repository;
  late final StreamSubscription<TrackerData> _subscription;

  Future<void> setPrayed(DateTime day, Prayer prayer, {required bool prayed}) =>
      _repository.setPrayed(day, prayer, prayed: prayed);

  Future<void> setQadaOwed(Prayer prayer, int count) =>
      _repository.setQadaOwed(prayer, count);

  Future<void> logQada(Prayer prayer) => _repository.logQada(prayer);

  Future<void> undoQada(Prayer prayer) => _repository.undoQada(prayer);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
