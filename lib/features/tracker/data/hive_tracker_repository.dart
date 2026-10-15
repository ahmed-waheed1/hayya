import 'dart:async';

import 'package:hive_ce/hive_ce.dart';

import '../../prayer_times/domain/entities/prayer.dart';
import '../domain/entities/calendar_day.dart';
import '../domain/entities/tracker_data.dart';
import '../domain/repositories/tracker_repository.dart';

/// [TrackerRepository] in a local Hive box. Nothing is sent anywhere.
///
/// Plain keys and ints, so no type adapters are needed:
/// - `since`: the first day tracked, "2026-10-15".
/// - `day:2026-10-15`: the prayers prayed that day as a bit mask, bit i
///   for `trackedPrayers[i]`. Days with nothing prayed have no key.
/// - `qada:fajr` …: prayers owed. `qada_made_up`: made-up prayers logged.
class HiveTrackerRepository implements TrackerRepository {
  HiveTrackerRepository._(this._box) : _data = _read(_box);

  /// Box name on disk.
  static const boxName = 'tracker';

  /// Wraps [box], recording today as the first tracked day on first use.
  static Future<HiveTrackerRepository> open(
    Box<dynamic> box, {
    DateTime Function() clock = DateTime.now,
  }) async {
    if (_parseDate(box.get(_sinceKey)) == null) {
      await box.put(_sinceKey, _formatDate(clock()));
    }
    return HiveTrackerRepository._(box);
  }

  final Box<dynamic> _box;
  TrackerData _data;
  final _changes = StreamController<TrackerData>.broadcast();

  static const _sinceKey = 'since';
  static const _dayPrefix = 'day:';
  static const _qadaPrefix = 'qada:';
  static const _madeUpKey = 'qada_made_up';
  static const _maxOwed = 99999;

  @override
  TrackerData get data => _data;

  @override
  Stream<TrackerData> get changes => _changes.stream;

  @override
  Future<void> setPrayed(
    DateTime day,
    Prayer prayer, {
    required bool prayed,
  }) async {
    final bit = trackedPrayers.indexOf(prayer);
    if (bit < 0) return;
    final key = '$_dayPrefix${_formatDate(day)}';
    final old = _mask(_box.get(key));
    final mask = prayed ? old | (1 << bit) : old & ~(1 << bit);
    if (mask == old) return;
    if (mask == 0) {
      await _box.delete(key);
    } else {
      await _box.put(key, mask);
    }
    _refresh();
  }

  @override
  Future<void> setQadaOwed(Prayer prayer, int count) async {
    if (!trackedPrayers.contains(prayer)) return;
    await _box.put('$_qadaPrefix${prayer.name}', count.clamp(0, _maxOwed));
    _refresh();
  }

  @override
  Future<void> logQada(Prayer prayer) async {
    final owed = _data.owed(prayer);
    if (owed == 0) return;
    await _box.putAll({
      '$_qadaPrefix${prayer.name}': owed - 1,
      _madeUpKey: _data.qadaMadeUp + 1,
    });
    _refresh();
  }

  @override
  Future<void> undoQada(Prayer prayer) async {
    if (_data.qadaMadeUp == 0) return;
    await _box.putAll({
      '$_qadaPrefix${prayer.name}': (_data.owed(prayer) + 1).clamp(0, _maxOwed),
      _madeUpKey: _data.qadaMadeUp - 1,
    });
    _refresh();
  }

  void _refresh() {
    _data = _read(_box);
    _changes.add(_data);
  }

  static TrackerData _read(Box<dynamic> box) {
    final days = <DateTime, Set<Prayer>>{};
    final owed = <Prayer, int>{};
    for (final key in box.keys.whereType<String>()) {
      if (key.startsWith(_dayPrefix)) {
        final day = _parseDate(key.substring(_dayPrefix.length));
        if (day == null) continue;
        final mask = _mask(box.get(key));
        days[day] = {
          for (final (i, p) in trackedPrayers.indexed)
            if (mask & (1 << i) != 0) p,
        };
      } else if (key.startsWith(_qadaPrefix)) {
        final prayer = Prayer.values
            .asNameMap()[key.substring(_qadaPrefix.length)];
        final count = box.get(key);
        if (trackedPrayers.contains(prayer) && count is int && count > 0) {
          owed[prayer!] = count;
        }
      }
    }
    final madeUp = box.get(_madeUpKey);
    return TrackerData(
      since: _parseDate(box.get(_sinceKey)) ?? DateTime.now(),
      days: days,
      qadaOwed: owed,
      qadaMadeUp: madeUp is int && madeUp > 0 ? madeUp : 0,
    );
  }

  /// Only the five tracked bits; anything else stored is ignored.
  static int _mask(Object? value) =>
      value is int ? value & ((1 << trackedPrayers.length) - 1) : 0;

  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${two(date.month)}-${two(date.day)}';
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final [y, m, d] = parts.map(int.tryParse).toList();
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d).dateOnly;
  }
}
