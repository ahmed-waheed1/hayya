import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/di/injection.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/tracker/domain/repositories/tracker_repository.dart';

import '../../../helpers/pump_app.dart';

final today = DateTime(2026, 10, 15);
final yesterday = DateTime(2026, 10, 14);

Finder check(String prayer) => find.byWidgetPredicate(
  (w) => w is PrayedCheck && w.semanticLabel == 'Mark $prayer as prayed',
);

Future<void> pumpHomeAt(
  WidgetTester tester,
  DateTime now, {
  Map<String, Object> tracker = const {'since': '2026-10-01'},
}) async {
  await pumpHayyaApp(tester, now: () => now, tracker: tracker);
}

TrackerRepository get repository => getIt<TrackerRepository>();

void main() {
  testWidgets('only prayers that have begun can be checked', (tester) async {
    // 13:00 in Cairo: after Dhuhr, before Asr.
    await pumpHomeAt(tester, DateTime(2026, 10, 15, 13));
    PrayedCheck widget(String name) => tester.widget<PrayedCheck>(check(name));

    expect(widget('Fajr').onChanged, isNotNull);
    expect(widget('Dhuhr').onChanged, isNotNull);
    expect(widget('Asr').onChanged, isNull);
    expect(widget('Maghrib').onChanged, isNull);
    expect(widget('Isha').onChanged, isNull);
    expect(check('Sunrise'), findsNothing);
  });

  testWidgets('checking a prayer saves it for today', (tester) async {
    await pumpHomeAt(tester, DateTime(2026, 10, 15, 13));

    await tester.tap(check('Dhuhr'));
    await tester.pump();
    expect(repository.data.prayedOn(today), {Prayer.dhuhr});
    expect(tester.widget<PrayedCheck>(check('Dhuhr')).value, isTrue);

    await tester.tap(check('Dhuhr'));
    await tester.pump();
    expect(repository.data.prayedOn(today), isEmpty);
  });

  testWidgets('a future prayer cannot be checked', (tester) async {
    await pumpHomeAt(tester, DateTime(2026, 10, 15, 13));
    await tester.tap(check('Isha'), warnIfMissed: false);
    await tester.pump();
    expect(repository.data.prayedOn(today), isEmpty);
  });

  testWidgets('Isha checked after midnight counts for the day before', (
    tester,
  ) async {
    // 00:30 on the 15th: still the night of the 14th.
    await pumpHomeAt(tester, DateTime(2026, 10, 15, 0, 30));
    PrayedCheck widget(String name) => tester.widget<PrayedCheck>(check(name));
    expect(widget('Fajr').onChanged, isNull);
    expect(widget('Isha').onChanged, isNotNull);

    await tester.tap(check('Isha'));
    await tester.pump();
    expect(repository.data.prayedOn(yesterday), {Prayer.isha});
    expect(repository.data.prayedOn(today), isEmpty);
  });

  testWidgets("shows what's already saved", (tester) async {
    await pumpHomeAt(
      tester,
      DateTime(2026, 10, 15, 13),
      tracker: {'since': '2026-10-01', 'day:2026-10-15': 0x01},
    );
    expect(tester.widget<PrayedCheck>(check('Fajr')).value, isTrue);
    expect(tester.widget<PrayedCheck>(check('Dhuhr')).value, isFalse);
  });
}
