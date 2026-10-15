import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/tracker/data/hive_tracker_repository.dart';
import 'package:hayya/features/tracker/domain/entities/tracker_data.dart';
import 'package:hayya/features/tracker/presentation/cubit/tracker_cubit.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../helpers/pump_app.dart';

void main() {
  final installed = DateTime(2026, 10, 1, 9, 30);
  final day = DateTime(2026, 10, 15);

  Future<HiveTrackerRepository> repo([
    Map<String, Object> contents = const {},
  ]) async => HiveTrackerRepository.open(
    await openMemoryTrackerBox(contents),
    clock: () => installed,
  );

  group('install date', () {
    test('the first open records today as the start of tracking', () async {
      final r = await repo();
      expect(r.data.since, DateTime(2026, 10, 1));
      expect(r.data.hasNoPrayers, isTrue);
    });

    test('later opens keep the original date', () async {
      final r = await repo({'since': '2026-09-20'});
      expect(r.data.since, DateTime(2026, 9, 20));
    });

    test('a corrupt date is replaced with today', () async {
      final r = await repo({'since': 'yesterday'});
      expect(r.data.since, DateTime(2026, 10, 1));
    });
  });

  group('prayed prayers', () {
    test('marks and unmarks a prayer on a day', () async {
      final r = await repo();
      await r.setPrayed(day, Prayer.fajr, prayed: true);
      await r.setPrayed(day, Prayer.isha, prayed: true);
      expect(r.data.prayedOn(day), {Prayer.fajr, Prayer.isha});

      await r.setPrayed(day, Prayer.fajr, prayed: false);
      expect(r.data.prayedOn(day), {Prayer.isha});
    });

    test('any time of day refers to the same day', () async {
      final r = await repo();
      await r.setPrayed(
        DateTime(2026, 10, 15, 23, 59),
        Prayer.isha,
        prayed: true,
      );
      expect(r.data.prayedOn(DateTime(2026, 10, 15, 6)), {Prayer.isha});
    });

    test('a day with nothing prayed is removed, not stored as zero', () async {
      final box = await openMemoryTrackerBox();
      final r = await HiveTrackerRepository.open(box, clock: () => installed);
      await r.setPrayed(day, Prayer.asr, prayed: true);
      await r.setPrayed(day, Prayer.asr, prayed: false);
      expect(box.keys, ['since']);
      expect(r.data.days, isEmpty);
    });

    test('Sunrise is never stored', () async {
      final r = await repo();
      await r.setPrayed(day, Prayer.sunrise, prayed: true);
      expect(r.data.prayedOn(day), isEmpty);
    });

    test('every change is announced', () async {
      final r = await repo();
      final emitted = expectLater(
        r.changes.map((d) => d.prayedOn(day)),
        emitsInOrder([
          {Prayer.dhuhr},
          <Prayer>{},
        ]),
      );
      await r.setPrayed(day, Prayer.dhuhr, prayed: true);
      await r.setPrayed(day, Prayer.dhuhr, prayed: false);
      await emitted;
    });

    test('unknown or damaged entries are ignored', () async {
      final r = await repo({
        'since': '2026-10-01',
        'day:2026-10-14': 0xFF, // extra bits beyond the five prayers
        'day:not-a-date': 3,
        'day:2026-10-13': 'five',
        'qada:sunrise': 4,
        'qada:fajr': -2,
        'something_else': true,
      });
      expect(r.data.days, {
        DateTime(2026, 10, 14): {...trackedPrayers},
      });
      expect(r.data.qadaOwed, isEmpty);
    });
  });

  group('qada counter', () {
    test('starts at zero', () async {
      final r = await repo();
      expect(r.data.totalOwed, 0);
      expect(r.data.qadaMadeUp, 0);
    });

    test('the user sets what they owe per prayer', () async {
      final r = await repo();
      await r.setQadaOwed(Prayer.fajr, 9);
      await r.setQadaOwed(Prayer.isha, 5);
      expect(r.data.owed(Prayer.fajr), 9);
      expect(r.data.owed(Prayer.isha), 5);
      expect(r.data.owed(Prayer.dhuhr), 0);
      expect(r.data.totalOwed, 14);
    });

    test('counts are kept between 0 and 99999', () async {
      final r = await repo();
      await r.setQadaOwed(Prayer.asr, -3);
      await r.setQadaOwed(Prayer.maghrib, 1000000);
      expect(r.data.owed(Prayer.asr), 0);
      expect(r.data.owed(Prayer.maghrib), 99999);
    });

    test('logging a made-up prayer counts it down', () async {
      final r = await repo();
      await r.setQadaOwed(Prayer.fajr, 2);
      await r.logQada(Prayer.fajr);
      expect(r.data.owed(Prayer.fajr), 1);
      expect(r.data.qadaMadeUp, 1);
      await r.logQada(Prayer.fajr);
      expect(r.data.owed(Prayer.fajr), 0);
      expect(r.data.qadaMadeUp, 2);
    });

    test('never goes below zero', () async {
      final r = await repo();
      await r.logQada(Prayer.dhuhr);
      expect(r.data.owed(Prayer.dhuhr), 0);
      expect(r.data.qadaMadeUp, 0);
    });

    test('only the logged prayer changes', () async {
      final r = await repo();
      await r.setQadaOwed(Prayer.fajr, 3);
      await r.setQadaOwed(Prayer.asr, 4);
      await r.logQada(Prayer.asr);
      expect(r.data.owed(Prayer.fajr), 3);
      expect(r.data.owed(Prayer.asr), 3);
    });

    test('undo puts the prayer back', () async {
      final r = await repo();
      await r.setQadaOwed(Prayer.maghrib, 1);
      await r.logQada(Prayer.maghrib);
      await r.undoQada(Prayer.maghrib);
      expect(r.data.owed(Prayer.maghrib), 1);
      expect(r.data.qadaMadeUp, 0);
    });

    test('undo without a log does nothing', () async {
      final r = await repo();
      await r.undoQada(Prayer.maghrib);
      expect(r.data.owed(Prayer.maghrib), 0);
    });
  });

  group('on disk', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('hayya_tracker_');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('everything survives closing and reopening the box', () async {
      var box = await Hive.openBox<dynamic>(HiveTrackerRepository.boxName);
      var r = await HiveTrackerRepository.open(box, clock: () => installed);
      await r.setPrayed(day, Prayer.fajr, prayed: true);
      await r.setPrayed(day, Prayer.maghrib, prayed: true);
      await r.setPrayed(DateTime(2026, 9, 1), Prayer.isha, prayed: true);
      await r.setQadaOwed(Prayer.asr, 7);
      await r.logQada(Prayer.asr);
      await box.close();

      box = await Hive.openBox<dynamic>(HiveTrackerRepository.boxName);
      // A later launch: the install date must not move.
      r = await HiveTrackerRepository.open(
        box,
        clock: () => DateTime(2026, 12, 25),
      );
      expect(r.data.since, DateTime(2026, 10, 1));
      expect(r.data.prayedOn(day), {Prayer.fajr, Prayer.maghrib});
      expect(r.data.prayedOn(DateTime(2026, 9, 1)), {Prayer.isha});
      expect(r.data.owed(Prayer.asr), 6);
      expect(r.data.qadaMadeUp, 1);
    });
  });

  group('TrackerCubit', () {
    test('follows the repository', () async {
      final r = await repo();
      final cubit = TrackerCubit(r);
      addTearDown(cubit.close);

      await cubit.setPrayed(day, Prayer.fajr, prayed: true);
      await cubit.setQadaOwed(Prayer.isha, 2);
      await cubit.logQada(Prayer.isha);
      await pumpEventQueue();

      expect(cubit.state.prayedOn(day), {Prayer.fajr});
      expect(cubit.state.owed(Prayer.isha), 1);
      expect(cubit.state, r.data);
    });
  });
}
