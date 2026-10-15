import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hayya/core/di/injection.dart';
import 'package:hayya/core/router/app_router.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/presentation/home_screen.dart';
import 'package:hayya/features/tracker/domain/entities/calendar_day.dart';
import 'package:hayya/features/tracker/domain/repositories/tracker_repository.dart';
import 'package:hayya/features/tracker/presentation/tracker_screen.dart';
import 'package:hayya/features/tracker/presentation/widgets/missed_chart.dart';
import 'package:hayya/features/tracker/presentation/widgets/prayer_heatmap.dart';

import '../../../helpers/pump_app.dart';

const tabletPortrait = Size(834, 1194);

/// 13:00 in Cairo: Fajr and Dhuhr have begun today.
final now = DateTime(2026, 10, 15, 13);
final today = DateTime(2026, 10, 15);

String key(DateTime day) =>
    'day:${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Installed 40 days ago. The last 12 days complete, a gap with Fajr
/// missed before that, and Fajr and Dhuhr prayed today.
Map<String, Object> history() => {
  'since': '2026-09-05',
  for (var i = 1; i <= 12; i++) key(today.addDays(-i)): 0x1F,
  key(today.addDays(-13)): 0x1E, // all but Fajr
  for (var i = 14; i <= 30; i++) key(today.addDays(-i)): i.isEven ? 0x1F : 0x0E,
  key(today): 0x03,
  'qada:fajr': 9,
  'qada:dhuhr': 3,
  'qada:asr': 4,
  'qada:maghrib': 2,
  'qada:isha': 5,
};

Future<void> pumpTracker(
  WidgetTester tester, {
  String lang = 'en',
  String theme = 'light',
  Size size = phoneSize,
  Map<String, Object>? tracker,
}) async {
  await pumpHayyaApp(
    tester,
    size: size,
    prefs: {'language_code': lang, 'theme_mode': theme},
    now: () => now,
    tracker: tracker ?? {'since': '2026-10-15'},
  );
  GoRouter.of(tester.element(find.byType(HomeScreen))).go(AppRoutes.tracker);
  await settle(tester, rounds: 3);
  expect(find.byType(TrackerScreen), findsOneWidget);
}

/// Scrolls through the whole screen so every card lays out.
Future<void> scrollThrough(WidgetTester tester) async {
  final scrollable = find.descendant(
    of: find.byType(TrackerScreen),
    matching: find.byType(Scrollable),
  );
  for (var i = 0; i < 6; i++) {
    await tester.drag(scrollable.first, const Offset(0, -300));
    await tester.pump();
  }
}

TrackerRepository get repository => getIt<TrackerRepository>();

void main() {
  group('a new user', () {
    testWidgets('sees a welcome instead of empty stats', (tester) async {
      await pumpTracker(tester);

      expect(find.text('Your journey starts today'), findsOneWidget);
      expect(find.byType(StatTile), findsNothing);
      expect(find.byType(MissedChart), findsNothing);
      expect(find.byType(PrayerHeatmap), findsOneWidget);
      expect(find.text('Add prayers to make up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Go to Home goes to Home', (tester) async {
      await pumpTracker(tester);
      await tester.tap(find.text('Go to Home'));
      await settle(tester, rounds: 2);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('days before install are not shown as missed', (tester) async {
      await pumpTracker(tester);
      final heatmap = tester.widget<PrayerHeatmap>(find.byType(PrayerHeatmap));
      // Only today is known, with nothing prayed yet.
      expect(heatmap.levelOf(today), 0);
      expect(heatmap.levelOf(today.addDays(-1)), isNull);
      expect(heatmap.levelOf(today.addDays(1)), isNull);
    });
  });

  group('with history', () {
    testWidgets('shows streak, last 7 days, heatmap and chart', (tester) async {
      await pumpTracker(tester, tracker: history());

      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('12 days', findRichText: true), findsOneWidget);
      // 6 complete days + 2 of today's 2 due prayers: 32 / 32.
      expect(
        find.text('100% 32\u00a0/\u00a032', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Last 16 weeks'), findsOneWidget);
      expect(find.text('Your journey starts today'), findsNothing);

      final heatmap = tester.widget<PrayerHeatmap>(find.byType(PrayerHeatmap));
      expect(heatmap.levelOf(today), 2);
      expect(heatmap.levelOf(today.addDays(-1)), 5);
      expect(heatmap.levelOf(today.addDays(-13)), 4);
      expect(heatmap.levelOf(DateTime(2026, 9, 5)), 0);
      // Installed 5 September: earlier days have no data.
      expect(heatmap.levelOf(DateTime(2026, 9, 4)), isNull);

      await scrollThrough(tester);
      expect(find.byType(MissedChart), findsOneWidget);
      expect(
        find.text(
          'Fajr is missed most. A reminder before the adhan might help.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic: RTL with Arabic-Indic digits only', (tester) async {
      await pumpTracker(tester, lang: 'ar', theme: 'dark', tracker: history());

      expect(find.text('١٢ يومًا', findRichText: true), findsOneWidget);
      expect(
        find.text('١٠٠٪ ٣٢\u00a0/\u00a0٣٢', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('آخر ١٦ أسبوعًا'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(PrayerHeatmap))),
        TextDirection.rtl,
      );
      await scrollThrough(tester);
      expect(find.textContaining(RegExp('[0-9]')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('layout', () {
    for (final lang in ['en', 'ar']) {
      for (final (label, size) in [
        ('phone', phoneSize),
        ('small phone', const Size(320, 640)),
        ('tablet portrait', tabletPortrait),
        ('tablet landscape', tabletSize),
      ]) {
        for (final (state, data) in [
          ('new', <String, Object>{'since': '2026-10-15'}),
          ('history', history()),
        ]) {
          testWidgets('$lang $label $state: no overflow', (tester) async {
            await pumpTracker(tester, lang: lang, size: size, tracker: data);
            await scrollThrough(tester);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    for (final lang in ['en', 'ar']) {
      testWidgets('$lang small phone: the sheets fit', (tester) async {
        await pumpTracker(
          tester,
          lang: lang,
          size: const Size(320, 640),
          tracker: history(),
        );
        await tapDay(tester, DateTime(2026, 9, 30));
        await settle(tester, rounds: 2);
        expect(find.byType(PrayedCheck), findsNWidgets(5));
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(PrayedCheck).first)).pop();
        await settle(tester, rounds: 2);

        await scrollThrough(tester);
        await tapVisible(
          tester,
          find.text(lang == 'en' ? 'Edit counts' : 'تعديل العدد'),
        );
        await settle(tester, rounds: 2);
        expect(find.byType(TextField), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tablets show more weeks, side by side', (tester) async {
      await pumpTracker(tester, size: tabletSize, tracker: history());
      final heatmap = tester.widget<PrayerHeatmap>(find.byType(PrayerHeatmap));
      expect(heatmap.weeks, greaterThan(16));
      final chart = tester.getTopLeft(find.byType(MissedChart));
      final grid = tester.getTopLeft(find.byType(PrayerHeatmap));
      expect(chart.dx, greaterThan(grid.dx));
    });
  });

  group('heatmap', () {
    for (final lang in ['en', 'ar']) {
      testWidgets('$lang: a tap opens the day under it', (tester) async {
        await pumpTracker(tester, lang: lang, tracker: history());
        // Newest week at the end edge: right in English, left in Arabic.
        final grid = tester.getRect(find.byKey(PrayerHeatmap.gridKey));
        final heatmap = tester.widget<PrayerHeatmap>(
          find.byType(PrayerHeatmap),
        );
        final cell = heatmap.cellRect(
          today,
          lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(
          cell.center.dx,
          lang == 'ar'
              ? lessThan(grid.width / 4)
              : greaterThan(grid.width * 3 / 4),
        );

        await tapDay(tester, DateTime(2026, 9, 30));
        await settle(tester, rounds: 2);
        expect(
          find.text(
            lang == 'ar'
                ? 'الأربعاء، ٣٠ سبتمبر ٢٠٢٦'
                : 'Wednesday, 30 September 2026',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('tapping a past day edits it', (tester) async {
      await pumpTracker(tester, tracker: history());
      final day = today.addDays(-13);

      await tapDay(tester, day);
      await settle(tester, rounds: 2);

      expect(find.text('Friday, 2 October 2026'), findsOneWidget);
      expect(find.text('4 of 5 prayed'), findsOneWidget);
      await tester.tap(_check('Fajr'));
      await tester.pump();
      expect(repository.data.prayedOn(day), hasLength(5));
      expect(find.text('5 of 5 prayed'), findsOneWidget);

      // The streak now runs through that day.
      await tester.tap(find.text('Done'));
      await settle(tester, rounds: 2);
      expect(find.text('14 days', findRichText: true), findsOneWidget);
    });

    testWidgets('today: prayers that have not begun cannot be ticked', (
      tester,
    ) async {
      await pumpTracker(tester, tracker: history());
      await tapDay(tester, today);
      await settle(tester, rounds: 2);

      PrayedCheck check(String name) =>
          tester.widget<PrayedCheck>(_check(name));
      expect(check('Fajr').onChanged, isNotNull);
      expect(check('Dhuhr').onChanged, isNotNull);
      expect(check('Asr').onChanged, isNull);
      expect(check('Maghrib').onChanged, isNull);
      expect(check('Isha').onChanged, isNull);
      expect(
        find.text("Prayers that haven't started yet can't be ticked."),
        findsOneWidget,
      );
      // No way forward from today.
      await tester.tap(find.bySemanticsLabel('Next day'));
      await tester.pump();
      expect(find.text('Thursday, 15 October 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Previous day'));
      await tester.pump();
      expect(find.text('Wednesday, 14 October 2026'), findsOneWidget);
    });

    testWidgets('future days do nothing', (tester) async {
      await pumpTracker(tester, tracker: history());
      await tapDay(tester, today.addDays(1));
      await settle(tester, rounds: 2);
      expect(find.byType(PrayedCheck), findsNothing);
    });
  });

  group('qada', () {
    testWidgets('set what is owed, log one, undo it', (tester) async {
      await pumpTracker(tester);
      await scrollThrough(tester);

      await tester.tap(find.text('Add prayers to make up'));
      await settle(tester, rounds: 2);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.bySemanticsLabel('One more Fajr'));
        await tester.pump();
      }
      await tester.enterText(find.byType(TextField).last, '12');
      await tester.tap(find.text('Save'));
      await settle(tester, rounds: 2);

      expect(repository.data.owed(Prayer.fajr), 3);
      expect(repository.data.owed(Prayer.isha), 12);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Log a made-up Fajr'), findsOneWidget);

      await tapVisible(tester, find.text('Log a made-up Fajr'));
      await tester.pump();
      expect(repository.data.owed(Prayer.fajr), 2);
      expect(find.text('14'), findsOneWidget);
      expect(
        find.text('Logged one made-up Fajr. May Allah accept it.'),
        findsOneWidget,
      );

      await tapVisible(tester, find.text('Undo'));
      await tester.pump();
      expect(repository.data.owed(Prayer.fajr), 3);
      expect(find.text('15'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('picks another prayer; logging stops at zero', (tester) async {
      await pumpTracker(
        tester,
        tracker: {'since': '2026-10-15', 'qada:asr': 1, 'qada:isha': 2},
      );
      await scrollThrough(tester);
      // Starts on the first prayer that is owed.
      expect(find.text('Log a made-up Asr'), findsOneWidget);
      await tester.tap(find.text('Log a made-up Asr'));
      await tester.pump();

      final logAsr = tester.widget<HayyaButton>(
        find.widgetWithText(HayyaButton, 'Log a made-up Asr'),
      );
      expect(logAsr.onPressed, isNull);

      await tester.tap(find.bySemanticsLabel('Isha: 2 to make up'));
      await tester.pump();
      await tester.tap(find.text('Log a made-up Isha'));
      await tester.pump();
      expect(repository.data.owed(Prayer.isha), 1);
    });

    testWidgets('Arabic digits are accepted when typing counts', (
      tester,
    ) async {
      await pumpTracker(tester, lang: 'ar');
      await scrollThrough(tester);
      await tester.tap(find.text('إضافة صلوات للقضاء'));
      await settle(tester, rounds: 2);
      await tester.enterText(find.byType(TextField).first, '٢٥');
      await tester.tap(find.text('حفظ'));
      await settle(tester, rounds: 2);
      expect(repository.data.owed(Prayer.fajr), 25);
      expect(find.text('٢٥'), findsWidgets);
    });

    testWidgets('all made up: an encouraging note', (tester) async {
      await pumpTracker(
        tester,
        tracker: {'since': '2026-10-15', 'qada_made_up': 40},
      );
      await scrollThrough(tester);
      expect(find.text('All made up. May Allah accept it.'), findsOneWidget);
    });
  });
}

/// Taps [day]'s cell in the heatmap.
Future<void> tapDay(WidgetTester tester, DateTime day) async {
  final grid = find.byKey(PrayerHeatmap.gridKey);
  final heatmap = tester.widget<PrayerHeatmap>(find.byType(PrayerHeatmap));
  final cell = heatmap.cellRect(day, Directionality.of(tester.element(grid)));
  await tester.tapAt(tester.getTopLeft(grid) + cell.center);
}

Finder _check(String prayer) => find.byWidgetPredicate(
  (w) => w is PrayedCheck && w.semanticLabel == 'Mark $prayer as prayed',
);
