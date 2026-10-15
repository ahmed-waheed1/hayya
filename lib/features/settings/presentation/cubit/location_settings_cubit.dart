import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/user_location.dart';

/// Which half of the Location card is showing.
enum LocationSource { automatic, manual }

enum PlaceSearchStatus { idle, searching, done, failed }

class LocationSettingsState extends Equatable {
  const LocationSettingsState({
    required this.source,
    required this.usingManual,
    this.location,
    this.locating = false,
    this.failure,
    this.query = '',
    this.results = const [],
    this.searchStatus = PlaceSearchStatus.idle,
  });

  /// The tab the user is on. Picking "Manual" only shows the search; the
  /// device's location stays in use until a city is chosen.
  final LocationSource source;

  /// A chosen city is in use instead of the device's location.
  final bool usingManual;

  /// What prayer times are calculated for now.
  final UserLocation? location;

  /// A device fix is being looked up.
  final bool locating;

  /// Why the last device fix failed, until the next attempt.
  final LocationFailure? failure;

  final String query;
  final List<UserLocation> results;
  final PlaceSearchStatus searchStatus;

  LocationSettingsState copyWith({
    LocationSource? source,
    bool? usingManual,
    UserLocation? location,
    bool? locating,
    LocationFailure? Function()? failure,
    String? query,
    List<UserLocation>? results,
    PlaceSearchStatus? searchStatus,
  }) => LocationSettingsState(
    source: source ?? this.source,
    usingManual: usingManual ?? this.usingManual,
    location: location ?? this.location,
    locating: locating ?? this.locating,
    failure: failure == null ? this.failure : failure(),
    query: query ?? this.query,
    results: results ?? this.results,
    searchStatus: searchStatus ?? this.searchStatus,
  );

  @override
  List<Object?> get props => [
    source,
    usingManual,
    location,
    locating,
    failure,
    query,
    results,
    searchStatus,
  ];
}

/// Settings → Location: the device's location with a refresh, or a city
/// searched for and picked by hand.
///
/// Changes go through [LocationService], which Home and the adhan
/// schedule follow.
class LocationSettingsCubit extends Cubit<LocationSettingsState> {
  LocationSettingsCubit(
    this._service, {
    this.debounce = const Duration(milliseconds: 400),
  }) : super(
         LocationSettingsState(
           source: _service.isManual
               ? LocationSource.manual
               : LocationSource.automatic,
           usingManual: _service.isManual,
           location: _service.lastKnown,
         ),
       ) {
    _changes = _service.changes.listen(
      (location) => emit(
        state.copyWith(location: location, usingManual: _service.isManual),
      ),
    );
  }

  final LocationService _service;

  /// How long typing must pause before a search runs.
  final Duration debounce;

  late final StreamSubscription<UserLocation> _changes;
  Timer? _debounceTimer;

  /// Queries shorter than this aren't searched.
  static const minQueryLength = 2;

  /// "Automatic": back to the device's location. While a chosen city is in
  /// use, that needs a fix; until one arrives the city stays.
  Future<void> showAutomatic() async {
    emit(state.copyWith(source: LocationSource.automatic));
    if (state.usingManual) await refresh();
  }

  void showManual() =>
      emit(state.copyWith(source: LocationSource.manual, failure: () => null));

  /// "Update location": a fresh device fix.
  Future<void> refresh() async {
    if (state.locating) return;
    emit(state.copyWith(locating: true, failure: () => null));
    final result = await _service.locateDevice();
    if (isClosed) return;
    switch (result) {
      case LocationFound(:final location):
        emit(
          state.copyWith(
            locating: false,
            location: location,
            usingManual: false,
          ),
        );
      case LocationFailed(:final reason):
        emit(
          state.copyWith(
            locating: false,
            failure: () => reason,
            // A chosen city is still in use; show it.
            source: _service.isManual ? LocationSource.manual : null,
          ),
        );
    }
  }

  Future<void> openSettingsFor(LocationFailure reason) =>
      reason == LocationFailure.serviceDisabled
      ? _service.openLocationSettings()
      : _service.openAppSettings();

  /// Searches [query] once typing pauses for [debounce].
  void search(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) {
      emit(
        state.copyWith(
          query: query,
          results: const [],
          searchStatus: PlaceSearchStatus.idle,
        ),
      );
      return;
    }
    emit(
      state.copyWith(query: query, searchStatus: PlaceSearchStatus.searching),
    );
    _debounceTimer = Timer(debounce, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    try {
      final results = await _service.searchPlaces(query);
      // A newer query has been typed meanwhile.
      if (isClosed || state.query != query) return;
      emit(
        state.copyWith(results: results, searchStatus: PlaceSearchStatus.done),
      );
    } on PlaceSearchException {
      if (isClosed || state.query != query) return;
      emit(
        state.copyWith(
          results: const [],
          searchStatus: PlaceSearchStatus.failed,
        ),
      );
    }
  }

  /// Uses [place] instead of the device's location.
  Future<void> choose(UserLocation place) async {
    _debounceTimer?.cancel();
    emit(
      state.copyWith(
        location: place,
        usingManual: true,
        failure: () => null,
        query: '',
        results: const [],
        searchStatus: PlaceSearchStatus.idle,
      ),
    );
    await _service.useManualLocation(place);
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    await _changes.cancel();
    return super.close();
  }
}
